//! Image decoding: detect format, decode JPEG/PNG/raw, produce PNG bytes + data URLs.

use crate::{
    error::{Error, Result},
    models::{DecodedImage, ImageFormat, ImageInfo},
};
use base64::{engine::general_purpose::STANDARD as B64, Engine};

/// Detect the image format from filter chain and raw bytes.
pub fn detect_format(info: &ImageInfo) -> ImageFormat {
    for f in &info.filters {
        match f.as_str() {
            "DCTDecode" => return ImageFormat::Jpeg,
            "FlateDecode" | "Fl" => return ImageFormat::Png,
            "JBIG2Decode" => return ImageFormat::Jbig2,
            "CCITTFaxDecode" => return ImageFormat::Ccitt,
            "LZWDecode" => return ImageFormat::Tiff,
            _ => {}
        }
    }
    // Sniff magic bytes
    if info.data.starts_with(&[0xFF, 0xD8, 0xFF]) {
        return ImageFormat::Jpeg;
    }
    if info.data.starts_with(&[0x89, b'P', b'N', b'G']) {
        return ImageFormat::Png;
    }
    if info.data.starts_with(b"II") || info.data.starts_with(b"MM") {
        return ImageFormat::Tiff;
    }
    ImageFormat::Raw
}

/// Decode an [`ImageInfo`] into a [`DecodedImage`] with ready-to-save bytes.
pub fn decode_image(info: &ImageInfo) -> Result<DecodedImage> {
    let fmt = detect_format(info);
    let (encoded, mime) = match fmt {
        ImageFormat::Jpeg => {
            // JPEG — return as-is
            (info.data.clone(), "image/jpeg")
        }
        ImageFormat::Png => {
            // Deflate-compressed. Try to reconstruct a valid PNG.
            let raw = inflate_zlib(&info.data).unwrap_or_else(|_| info.data.clone());
            let png = encode_raw_to_png(
                info.width.unwrap_or(1),
                info.height.unwrap_or(1),
                info.bits_per_component.unwrap_or(8),
                channels_from_cs(info.color_space.as_deref()),
                &raw,
                info.filters.contains(&"FlateDecode".to_owned()),
            )?;
            (png, "image/png")
        }
        ImageFormat::Raw => {
            let png = encode_raw_to_png(
                info.width.unwrap_or(1),
                info.height.unwrap_or(1),
                info.bits_per_component.unwrap_or(8),
                channels_from_cs(info.color_space.as_deref()),
                &info.data,
                false,
            )?;
            (png, "image/png")
        }
        _ => {
            // Unknown/JBIG2/CCITT — wrap in PNG container if possible, else return raw
            (info.data.clone(), "image/png")
        }
    };

    let data_url = format!("data:{};base64,{}", mime, B64.encode(&encoded));
    let mut new_info = info.clone();
    new_info.format = fmt;

    Ok(DecodedImage {
        info: new_info,
        encoded_bytes: encoded,
        mime_type: mime,
        data_url,
    })
}

fn inflate_zlib(data: &[u8]) -> Result<Vec<u8>> {
    use flate2::read::ZlibDecoder;
    use std::io::Read;
    let mut decoder = ZlibDecoder::new(data);
    let mut out = Vec::new();
    decoder
        .read_to_end(&mut out)
        .map_err(|e| Error::Internal(e.to_string()))?;
    Ok(out)
}

fn channels_from_cs(cs: Option<&str>) -> u8 {
    match cs {
        Some("DeviceCMYK") => 4,
        Some("DeviceRGB") | Some("CalRGB") => 3,
        _ => 1,
    }
}

/// Minimal PNG encoder (pure Rust, no external image crate needed).
/// Writes an 8-bit or 16-bit RGB/Gray PNG.
fn encode_raw_to_png(
    width: u32,
    height: u32,
    bpc: u32,
    channels: u8,
    raw: &[u8],
    already_filtered: bool,
) -> Result<Vec<u8>> {
    // Normalise to 8-bit
    let pixels: Vec<u8> = if bpc == 1 {
        // 1-bit bitmap → 8-bit
        let mut out = Vec::with_capacity((width * height * channels as u32) as usize);
        for byte in raw {
            for bit in (0..8).rev() {
                let v = if (byte >> bit) & 1 == 1 { 255 } else { 0 };
                for _ in 0..channels {
                    out.push(v);
                }
            }
        }
        out
    } else if bpc == 16 {
        raw.chunks_exact(2).map(|c| c[0]).collect()
    } else if already_filtered {
        // already a raw pixel stream after inflate
        raw.to_vec()
    } else {
        raw.to_vec()
    };

    let color_type: u8 = if channels == 1 {
        0
    } else if channels == 3 {
        2
    } else {
        2
    };

    let mut png = Vec::new();
    // PNG signature
    png.extend_from_slice(&[137, 80, 78, 71, 13, 10, 26, 10]);
    // IHDR
    write_chunk(&mut png, b"IHDR", &{
        let mut h = Vec::new();
        h.extend_from_slice(&width.to_be_bytes());
        h.extend_from_slice(&height.to_be_bytes());
        h.push(8); // bit depth
        h.push(color_type);
        h.extend_from_slice(&[0, 0, 0]); // compression, filter, interlace
        h
    });
    // IDAT — apply PNG filter (None=0) per row then zlib-compress
    let row_len = (width as usize) * (channels as usize);
    let mut raw_rows = Vec::with_capacity((row_len + 1) * height as usize);
    for row in 0..height as usize {
        raw_rows.push(0u8); // filter byte = None
        let start = row * row_len;
        let end = (start + row_len).min(pixels.len());
        if end > start {
            raw_rows.extend_from_slice(&pixels[start..end]);
        } else {
            raw_rows.extend(std::iter::repeat(0u8).take(row_len));
        }
    }
    use flate2::{write::ZlibEncoder, Compression};
    use std::io::Write;
    let mut enc = ZlibEncoder::new(Vec::new(), Compression::fast());
    enc.write_all(&raw_rows)
        .map_err(|e| Error::Internal(e.to_string()))?;
    let compressed = enc.finish().map_err(|e| Error::Internal(e.to_string()))?;
    write_chunk(&mut png, b"IDAT", &compressed);
    // IEND
    write_chunk(&mut png, b"IEND", &[]);

    Ok(png)
}

fn write_chunk(out: &mut Vec<u8>, chunk_type: &[u8; 4], data: &[u8]) {
    let len = data.len() as u32;
    out.extend_from_slice(&len.to_be_bytes());
    out.extend_from_slice(chunk_type);
    out.extend_from_slice(data);
    let crc = crc32(chunk_type, data);
    out.extend_from_slice(&crc.to_be_bytes());
}

/// Simple CRC-32 using the standard polynomial (no dep needed).
fn crc32(type_bytes: &[u8], data: &[u8]) -> u32 {
    let table: [u32; 256] = {
        let mut t = [0u32; 256];
        for n in 0usize..256 {
            let mut c = n as u32;
            for _ in 0..8 {
                c = if c & 1 != 0 {
                    0xEDB88320 ^ (c >> 1)
                } else {
                    c >> 1
                };
            }
            t[n] = c;
        }
        t
    };
    let mut crc: u32 = 0xFFFFFFFF;
    for &b in type_bytes.iter().chain(data.iter()) {
        crc = table[((crc ^ b as u32) & 0xFF) as usize] ^ (crc >> 8);
    }
    crc ^ 0xFFFFFFFF
}
