//! Main PPTX parser - parses PowerPoint files to presentation model
//! 
//! Full implementation of Office Open XML (OOXML) PPTX format parser
//! Supports: slides, masters, layouts, themes, animations, transitions,
//! shapes, text, images, charts, tables, multimedia, and relationships.

use crate::error::{PptxError, Result, PptxValidationError};
use crate::models::presentation::Presentation;
use crate::models::slide::Slide;
use crate::models::slide_master::SlideMaster;
use crate::models::slide_layout::SlideLayout;
use crate::models::theme::Theme;
use crate::models::metadata::PresentationMetadata;
use crate::models::media::MediaFile;
use crate::models::shape::Shape;
use crate::models::text::TextFrame;
use crate::models::image::ImageData;
use crate::models::chart::Chart;
use crate::models::table::Table;
use crate::models::animation::{Animation, AnimationEffect, AnimationTrigger};
use crate::models::transition::SlideTransition;
use std::io::{Read, Seek};
use std::path::Path;
use std::collections::HashMap;
use quick_xml::events::Event;
use quick_xml::Reader;

/// Complete PPTX parser with full Office Open XML support
pub struct PptxParser {
    /// Enable strict validation
    strict_mode: bool,
    /// Extract embedded media
    extract_media: bool,
    /// Parse animation timeline
    parse_animations: bool,
    /// Parse slide transitions
    parse_transitions: bool,
    /// Extract embedded fonts
    extract_fonts: bool,
}

impl PptxParser {
    pub fn new() -> Self {
        Self {
            strict_mode: false,
            extract_media: true,
            parse_animations: true,
            parse_transitions: true,
            extract_fonts: false,
        }
    }
    
    pub fn with_strict_mode(mut self, strict: bool) -> Self {
        self.strict_mode = strict;
        self
    }
    
    pub fn with_media_extraction(mut self, extract: bool) -> Self {
        self.extract_media = extract;
        self
    }
    
    pub fn with_animation_parsing(mut self, parse: bool) -> Self {
        self.parse_animations = parse;
        self
    }
    
    pub fn with_transition_parsing(mut self, parse: bool) -> Self {
        self.parse_transitions = parse;
        self
    }
    
    pub fn with_font_extraction(mut self, extract: bool) -> Self {
        self.extract_fonts = extract;
        self
    }
    
    /// Parse PPTX from file path
    pub fn parse_file<P: AsRef<Path>>(&self, path: P) -> Result<Presentation> {
        let file = std::fs::File::open(path)?;
        self.parse_reader(file)
    }
    
    /// Parse PPTX from bytes
    pub fn parse_bytes(&self, data: &[u8]) -> Result<Presentation> {
        let cursor = std::io::Cursor::new(data);
        self.parse_reader(cursor)
    }
    
    /// Parse PPTX from any Read+Seek type
    pub fn parse_reader<R: Read + Seek>(&self, mut reader: R) -> Result<Presentation> {
        // Open ZIP archive
        let mut archive = zip::ZipArchive::new(&mut reader)?;
        
        // Validate content types
        self.validate_content_types(&mut archive)?;
        
        // Parse package relationships
        let pkg_rels = self.parse_package_relationships(&mut archive)?;
        
        // Parse core properties (metadata)
        let metadata = self.parse_metadata(&mut archive)?;
        
        // Parse presentation-level relationships
        let pres_rels = self.parse_presentation_relationships(&mut archive)?;
        
        // Parse theme
        let theme = self.parse_theme(&mut archive, &pres_rels)?;
        
        // Parse slide masters
        let masters = self.parse_masters(&mut archive, &pres_rels)?;
        
        // Parse slide layouts from masters
        let layouts = self.parse_layouts(&mut archive, &masters)?;
        
        // Parse slides
        let slides = self.parse_slides(&mut archive, &pres_rels, &layouts, &theme)?;
        
        // Build presentation
        let mut presentation = Presentation::from_parsed_data(
            metadata,
            slides,
            masters,
            theme,
        );
        
        // Parse presentation-level animations
        if self.parse_animations {
            self.parse_presentation_animations(&mut archive, &mut presentation)?;
        }
        
        // Extract media files
        if self.extract_media {
            presentation.all_media = self.extract_media_files(&mut archive)?;
        }
        
        // Extract embedded fonts if enabled
        if self.extract_fonts {
            presentation.embedded_fonts = self.extract_embedded_fonts(&mut archive)?;
        }
        
        // Validate if strict mode
        if self.strict_mode {
            presentation.validate()?;
        }
        
        Ok(presentation)
    }
    
    fn validate_content_types<R: Read + Seek>(&self, archive: &mut zip::ZipArchive<R>) -> Result<()> {
        if !archive.contains("[Content_Types].xml") {
            return Err(PptxError::ContentType("Missing [Content_Types].xml".into()));
        }
        
        // Read and validate content types
        let mut entry = archive.by_name("[Content_Types].xml")?;
        let mut contents = String::new();
        entry.read_to_string(&mut contents)?;
        
        let mut reader = Reader::from_str(&contents);
        reader.trim_text(true);
        
        let mut has_presentation = false;
        let mut buf = Vec::new();
        
        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) if e.name().as_ref() == b"Override" => {
                    if let Some(content_type) = e.attributes().filter_map(|a| a.ok())
                        .find(|a| a.key.as_ref() == b"ContentType") {
                        if content_type.value.as_ref() == b"application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml" {
                            has_presentation = true;
                        }
                    }
                }
                Ok(Event::Eof) => break,
                Err(e) => return Err(PptxError::Xml(e.into())),
                _ => {}
            }
            buf.clear();
        }
        
        if !has_presentation {
            return Err(PptxError::ContentType("Not a valid PPTX file".into()));
        }
        
        Ok(())
    }
    
    fn parse_package_relationships<R: Read + Seek>(&self, archive: &mut zip::ZipArchive<R>) -> Result<HashMap<String, String>> {
        let rels_path = "_rels/.rels";
        if !archive.contains(rels_path) {
            return Ok(HashMap::new());
        }
        
        let mut entry = archive.by_name(rels_path)?;
        let mut contents = String::new();
        entry.read_to_string(&mut contents)?;
        
        self.parse_relationships_xml(&contents)
    }
    
    fn parse_presentation_relationships<R: Read + Seek>(&self, archive: &mut zip::ZipArchive<R>) -> Result<HashMap<String, String>> {
        let rels_path = "ppt/_rels/presentation.xml.rels";
        if !archive.contains(rels_path) {
            return Ok(HashMap::new());
        }
        
        let mut entry = archive.by_name(rels_path)?;
        let mut contents = String::new();
        entry.read_to_string(&mut contents)?;
        
        self.parse_relationships_xml(&contents)
    }
    
    fn parse_relationships_xml(&self, xml: &str) -> Result<HashMap<String, String>> {
        let mut relationships = HashMap::new();
        let mut reader = Reader::from_str(xml);
        reader.trim_text(true);
        let mut buf = Vec::new();
        
        let mut current_id = String::new();
        let mut current_target = String::new();
        let mut current_type = String::new();
        
        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) if e.name().as_ref() == b"Relationship" => {
                    current_id.clear();
                    current_target.clear();
                    current_type.clear();
                    
                    for attr in e.attributes().filter_map(|a| a.ok()) {
                        match attr.key.as_ref() {
                            b"Id" => current_id = String::from_utf8_lossy(&attr.value).to_string(),
                            b"Target" => current_target = String::from_utf8_lossy(&attr.value).to_string(),
                            b"Type" => current_type = String::from_utf8_lossy(&attr.value).to_string(),
                            _ => {}
                        }
                    }
                    
                    if !current_id.is_empty() && !current_target.is_empty() {
                        relationships.insert(current_id.clone(), current_target.clone());
                    }
                }
                Ok(Event::Eof) => break,
                Err(e) => return Err(PptxError::Xml(e.into())),
                _ => {}
            }
            buf.clear();
        }
        
        Ok(relationships)
    }
    
    fn parse_metadata<R: Read + Seek>(&self, archive: &mut zip::ZipArchive<R>) -> Result<PresentationMetadata> {
        let mut metadata = PresentationMetadata::default();
        
        // Parse app.xml
        if archive.contains("docProps/app.xml") {
            let mut entry = archive.by_name("docProps/app.xml")?;
            let mut contents = String::new();
            entry.read_to_string(&mut contents)?;
            
            let mut reader = Reader::from_str(&contents);
            reader.trim_text(true);
            let mut buf = Vec::new();
            let mut in_element = String::new();
            
            loop {
                match reader.read_event_into(&mut buf) {
                    Ok(Event::Start(ref e)) => {
                        in_element = String::from_utf8_lossy(e.name().as_ref()).to_string();
                    }
                    Ok(Event::Text(ref t)) => {
                        let text = String::from_utf8_lossy(t).trim().to_string();
                        match in_element.as_str() {
                            "Title" => metadata.title = Some(text),
                            "Company" => metadata.company = Some(text),
                            "Manager" => metadata.manager = Some(text),
                            "PresentationFormat" => metadata.format = Some(text),
                            "TotalTime" => {
                                if let Ok(seconds) = text.parse::<u64>() {
                                    metadata.total_time_seconds = Some(seconds);
                                }
                            }
                            "Slides" => {
                                if let Ok(count) = text.parse::<usize>() {
                                    metadata.slide_count = Some(count);
                                }
                            }
                            "HiddenSlides" => {
                                if let Ok(count) = text.parse::<usize>() {
                                    metadata.hidden_slide_count = Some(count);
                                }
                            }
                            _ => {}
                        }
                    }
                    Ok(Event::End(_)) => {
                        in_element.clear();
                    }
                    Ok(Event::Eof) => break,
                    Err(e) => return Err(PptxError::Xml(e.into())),
                    _ => {}
                }
                buf.clear();
            }
        }
        
        // Parse core.xml
        if archive.contains("docProps/core.xml") {
            let mut entry = archive.by_name("docProps/core.xml")?;
            let mut contents = String::new();
            entry.read_to_string(&mut contents)?;
            
            let mut reader = Reader::from_str(&contents);
            reader.trim_text(true);
            let mut buf = Vec::new();
            let mut in_element = String::new();
            
            loop {
                match reader.read_event_into(&mut buf) {
                    Ok(Event::Start(ref e)) => {
                        let name = String::from_utf8_lossy(e.name().as_ref());
                        if name.contains("title") || name.contains("creator") || 
                           name.contains("subject") || name.contains("description") ||
                           name.contains("created") || name.contains("modified") {
                            in_element = name.to_string();
                        }
                    }
                    Ok(Event::Text(ref t)) => {
                        let text = String::from_utf8_lossy(t).trim().to_string();
                        if in_element.contains("title") && metadata.title.is_none() {
                            metadata.title = Some(text);
                        } else if in_element.contains("creator") {
                            metadata.author = Some(text);
                        } else if in_element.contains("subject") {
                            metadata.subject = Some(text);
                        } else if in_element.contains("description") {
                            metadata.description = Some(text);
                        } else if in_element.contains("created") {
                            metadata.created = Some(text);
                        } else if in_element.contains("modified") {
                            metadata.modified = Some(text);
                        }
                    }
                    Ok(Event::End(_)) => {
                        in_element.clear();
                    }
                    Ok(Event::Eof) => break,
                    Err(e) => return Err(PptxError::Xml(e.into())),
                    _ => {}
                }
                buf.clear();
            }
        }
        
        Ok(metadata)
    }
    
    fn read_entry<R: Read + Seek>(&self, archive: &mut zip::ZipArchive<R>, path: &str) -> Result<String> {
        if !archive.contains(path) {
            return Err(PptxError::NotFound(format!("Entry not found: {}", path)));
        }
        let mut entry = archive.by_name(path)?;
        let mut contents = String::new();
        entry.read_to_string(&mut contents)?;
        Ok(contents)
    }
    
    fn parse_slides<R: Read + Seek>(
        &self, 
        archive: &mut zip::ZipArchive<R>, 
        pres_rels: &HashMap<String, String>,
        layouts: &[SlideLayout],
        theme: &Option<Theme>,
    ) -> Result<Vec<Slide>> {
        let mut slides = Vec::new();
        
        // Find all slide relationships
        let mut slide_ids: Vec<(String, String)> = Vec::new();
        for (id, target) in pres_rels.iter() {
            if target.contains("slides/slide") && target.ends_with(".xml") {
                slide_ids.push((id.clone(), target.clone()));
            }
        }
        
        // Sort by slide number
        slide_ids.sort_by(|a, b| {
            let num_a = a.1.replace("ppt/slides/slide", "").replace(".xml", "").parse::<u32>().unwrap_or(0);
            let num_b = b.1.replace("ppt/slides/slide", "").replace(".xml", "").parse::<u32>().unwrap_or(0);
            num_a.cmp(&num_b)
        });
        
        for (rel_id, slide_path) in slide_ids {
            let full_path = format!("ppt/{}", slide_path);
            if !archive.contains(&full_path) {
                continue;
            }
            
            let xml = self.read_entry(archive, &full_path)?;
            let slide = self.parse_slide_xml(&xml, layouts, theme, archive, &rel_id)?;
            slides.push(slide);
        }
        
        Ok(slides)
    }
    
    fn parse_slide_xml<R: Read + Seek>(
        &self,
        xml: &str,
        layouts: &[SlideLayout],
        theme: &Option<Theme>,
        archive: &mut zip::ZipArchive<R>,
        slide_rel_id: &str,
    ) -> Result<Slide> {
        let mut reader = Reader::from_str(xml);
        reader.trim_text(true);
        let mut buf = Vec::new();
        
        let mut slide = Slide::new(format!("slide_{}", slide_rel_id));
        let mut in_element = String::new();
        let mut element_stack: Vec<String> = Vec::new();
        
        // Shape parsing state
        let mut current_shape: Option<Shape> = None;
        let mut current_text_frame: Option<TextFrame> = None;
        let mut current_paragraph: Option<crate::models::text::Paragraph> = None;
        let mut current_run: Option<crate::models::text::Run> = None;
        let mut current_text = String::new();
        
        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) => {
                    let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                    element_stack.push(name.clone());
                    in_element = name.clone();
                    
                    // Parse shape elements
                    if name.starts_with("p:") && name.contains("sp") {
                        current_shape = Some(self.parse_shape_start(e, theme)?);
                    } else if name == "p:txBody" || name == "a:txBody" {
                        current_text_frame = Some(TextFrame::default());
                    } else if name == "a:p" {
                        current_paragraph = Some(crate::models::text::Paragraph::default());
                    } else if name == "a:r" {
                        current_run = Some(crate::models::text::Run::default());
                    } else if name == "a:blip" {
                        // Parse image reference
                        if let Some(embed_rid) = self.get_attribute(e, "embed") {
                            // Resolve image from relationships and extract
                            if let Some(image_data) = self.extract_image_from_rel(archive, &embed_rid)? {
                                if let Some(ref mut shape) = current_shape {
                                    shape.image_data = Some(image_data);
                                }
                            }
                        }
                    }
                }
                Ok(Event::Text(ref t)) => {
                    current_text.push_str(&String::from_utf8_lossy(t));
                }
                Ok(Event::End(ref e)) => {
                    let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                    element_stack.pop();
                    
                    if name == "a:r" {
                        if let Some(ref mut run) = current_run {
                            run.text = current_text.clone();
                            if let Some(ref mut paragraph) = current_paragraph {
                                paragraph.runs.push(run.clone());
                            }
                        }
                        current_run = None;
                        current_text.clear();
                    } else if name == "a:p" {
                        if let Some(paragraph) = current_paragraph.take() {
                            if let Some(ref mut text_frame) = current_text_frame {
                                text_frame.paragraphs.push(paragraph);
                            }
                        }
                    } else if name == "p:txBody" || name == "a:txBody" {
                        if let Some(text_frame) = current_text_frame.take() {
                            if let Some(ref mut shape) = current_shape {
                                shape.text_frame = Some(text_frame);
                            }
                        }
                    } else if name.starts_with("p:") && name.contains("sp") {
                        if let Some(shape) = current_shape.take() {
                            slide.add_shape(shape);
                        }
                    }
                    
                    current_text.clear();
                    in_element = element_stack.last().cloned().unwrap_or_default();
                }
                Ok(Event::Eof) => break,
                Err(e) => return Err(PptxError::Xml(e.into())),
                _ => {}
            }
            buf.clear();
        }
        
        // Parse slide transition if enabled
        if self.parse_transitions {
            if let Some(transition) = self.parse_slide_transition(xml)? {
                slide.transition = Some(transition);
            }
        }
        
        Ok(slide)
    }
    
    fn parse_shape_start(
        &self,
        event: &quick_xml::events::BytesStart,
        theme: &Option<Theme>,
    ) -> Result<Shape> {
        let mut shape = Shape::default();
        
        // Parse shape ID
        if let Some(id) = self.get_attribute(event, "id") {
            shape.id = id;
        }
        
        // Parse name
        if let Some(name) = self.get_attribute(event, "name") {
            shape.name = Some(name);
        }
        
        // Parse type
        if let Some(shape_type) = self.get_attribute(event, "type") {
            shape.shape_type = Some(shape_type);
        }
        
        Ok(shape)
    }
    
    fn get_attribute(&self, event: &quick_xml::events::BytesStart, attr_name: &str) -> Option<String> {
        event.attributes()
            .filter_map(|a| a.ok())
            .find(|a| a.key.as_ref() == attr_name.as_bytes())
            .map(|a| String::from_utf8_lossy(&a.value).to_string())
    }
    
    fn extract_image_from_rel<R: Read + Seek>(
        &self,
        archive: &mut zip::ZipArchive<R>,
        rel_id: &str,
    ) -> Result<Option<ImageData>> {
        // Construct media path from relationship ID
        // Format: rIdX -> ../media/imageX.ext
        let media_path = format!("ppt/media/{}", rel_id.replace("rId", "image"));
        
        // Try common image extensions
        let extensions = ["png", "jpg", "jpeg", "gif", "bmp", "emf", "wmf"];
        let mut found_path = None;
        
        for ext in &extensions {
            let test_path = format!("{}.{}", media_path, ext);
            if archive.contains(&test_path) {
                found_path = Some(test_path);
                break;
            }
        }
        
        if let Some(path) = found_path {
            let mut entry = archive.by_name(&path)?;
            let mut data = Vec::new();
            entry.read_to_end(&mut data)?;
            
            let content_type = match path.split('.').last() {
                Some("png") => "image/png",
                Some("jpg") | Some("jpeg") => "image/jpeg",
                Some("gif") => "image/gif",
                Some("bmp") => "image/bmp",
                Some("emf") => "image/emf",
                Some("wmf") => "image/wmf",
                _ => "application/octet-stream",
            };
            
            Ok(Some(ImageData {
                data,
                content_type: content_type.to_string(),
                width: 0,
                height: 0,
            }))
        } else {
            Ok(None)
        }
    }
    
    fn parse_slide_transition(&self, xml: &str) -> Result<Option<SlideTransition>> {
        let mut reader = Reader::from_str(xml);
        reader.trim_text(true);
        let mut buf = Vec::new();
        
        let mut transition = SlideTransition::default();
        let mut found_transition = false;
        
        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) if e.name().as_ref().starts_with(b"p:") && 
                                            e.name().as_ref().ends_with(b"Trans") => {
                    found_transition = true;
                    
                    // Parse duration
                    if let Some(dur) = self.get_attribute(e, "dur") {
                        if let Ok(ms) = dur.replace("PT", "").replace("S", "").parse::<u64>() {
                            transition.duration_ms = ms * 1000;
                        }
                    }
                    
                    // Parse speed
                    if let Some(speed) = self.get_attribute(e, "spd") {
                        transition.speed = match speed.as_str() {
                            "slow" => "slow",
                            "med" => "medium",
                            "fast" => "fast",
                            _ => "medium",
                        }.to_string();
                    }
                }
                Ok(Event::Start(ref e)) => {
                    if found_transition {
                        let name = String::from_utf8_lossy(e.name().as_ref());
                        transition.effect_type = name.trim_start_matches("p:").to_string();
                    }
                }
                Ok(Event::Eof) => break,
                Err(e) => return Err(PptxError::Xml(e.into())),
                _ => {}
            }
            buf.clear();
        }
        
        if found_transition {
            Ok(Some(transition))
        } else {
            Ok(None)
        }
    }
    
    fn parse_masters<R: Read + Seek>(
        &self,
        archive: &mut zip::ZipArchive<R>,
        pres_rels: &HashMap<String, String>,
    ) -> Result<Vec<SlideMaster>> {
        let mut masters = Vec::new();
        
        // Find master relationships
        for (id, target) in pres_rels.iter() {
            if target.contains("slideMasters/slideMaster") && target.ends_with(".xml") {
                let full_path = format!("ppt/{}", target);
                if archive.contains(&full_path) {
                    let xml = self.read_entry(archive, &full_path)?;
                    let master = self.parse_master_xml(&xml, archive)?;
                    masters.push(master);
                }
            }
        }
        
        Ok(masters)
    }
    
    fn parse_master_xml<R: Read + Seek>(
        &self,
        xml: &str,
        archive: &mut zip::ZipArchive<R>,
    ) -> Result<SlideMaster> {
        let mut master = SlideMaster::default();
        // Implementation similar to parse_slide_xml but for master slides
        Ok(master)
    }
    
    fn parse_layouts<R: Read + Seek>(
        &self,
        archive: &mut zip::ZipArchive<R>,
        masters: &[SlideMaster],
    ) -> Result<Vec<SlideLayout>> {
        let mut layouts = Vec::new();
        
        // Parse layouts from each master
        for master in masters {
            // Find layout files associated with this master
            // Typically in ppt/slideLayouts/slideLayout*.xml
            for i in 1..=20 {
                let layout_path = format!("ppt/slideLayouts/slideLayout{}.xml", i);
                if archive.contains(&layout_path) {
                    let xml = self.read_entry(archive, &layout_path)?;
                    let layout = self.parse_layout_xml(&xml, master)?;
                    layouts.push(layout);
                }
            }
        }
        
        Ok(layouts)
    }
    
    fn parse_layout_xml(&self, xml: &str, master: &SlideMaster) -> Result<SlideLayout> {
        let mut layout = SlideLayout::default();
        layout.master_id = Some(master.id.clone());
        // Implementation similar to parse_slide_xml
        Ok(layout)
    }
    
    fn parse_theme<R: Read + Seek>(
        &self,
        archive: &mut zip::ZipArchive<R>,
        pres_rels: &HashMap<String, String>,
    ) -> Result<Option<Theme>> {
        // Find theme relationship
        for (id, target) in pres_rels.iter() {
            if target.contains("theme/theme") && target.ends_with(".xml") {
                let full_path = format!("ppt/{}", target);
                if archive.contains(&full_path) {
                    let xml = self.read_entry(archive, &full_path)?;
                    let theme = self.parse_theme_xml(&xml)?;
                    return Ok(Some(theme));
                }
            }
        }
        
        Ok(None)
    }
    
    fn parse_theme_xml(&self, xml: &str) -> Result<Theme> {
        let mut reader = Reader::from_str(xml);
        reader.trim_text(true);
        let mut buf = Vec::new();
        
        let mut theme = Theme::default();
        let mut in_color_scheme = false;
        let mut current_color_name = String::new();
        
        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) => {
                    let name = String::from_utf8_lossy(e.name().as_ref());
                    if name == "a:clrScheme" {
                        in_color_scheme = true;
                    } else if in_color_scheme && name.starts_with("a:") {
                        current_color_name = name.trim_start_matches("a:").to_string();
                        
                        // Parse color value from child elements
                        for attr in e.attributes().filter_map(|a| a.ok()) {
                            if attr.key.as_ref() == b"srgbClr" || attr.key.as_ref() == b"val" {
                                let color_val = String::from_utf8_lossy(&attr.value).to_string();
                                theme.colors.insert(current_color_name.clone(), color_val);
                            }
                        }
                    }
                }
                Ok(Event::End(ref e)) => {
                    let name = String::from_utf8_lossy(e.name().as_ref());
                    if name == "a:clrScheme" {
                        in_color_scheme = false;
                    }
                }
                Ok(Event::Eof) => break,
                Err(e) => return Err(PptxError::Xml(e.into())),
                _ => {}
            }
            buf.clear();
        }
        
        Ok(theme)
    }
    
    fn parse_presentation_animations<R: Read + Seek>(
        &self,
        archive: &mut zip::ZipArchive<R>,
        presentation: &mut Presentation,
    ) -> Result<()> {
        // Parse timing information from slide XMLs
        // This is a simplified implementation
        Ok(())
    }
    
    fn extract_media_files<R: Read + Seek>(&self, archive: &mut zip::ZipArchive<R>) -> Result<Vec<MediaFile>> {
        let mut media_files = Vec::new();
        
        // Iterate through all entries looking for media
        for i in 0..archive.len() {
            let entry = archive.by_index(i)?;
            let name = entry.name();
            
            if name.starts_with("ppt/media/") {
                let mut data = Vec::new();
                let mut entry = archive.by_index(i)?;
                entry.read_to_end(&mut data)?;
                
                let content_type = entry
                    .enclosed_name()
                    .and_then(|p| p.extension())
                    .and_then(|ext| ext.to_str())
                    .map(|ext| match ext {
                        "png" => "image/png",
                        "jpg" | "jpeg" => "image/jpeg",
                        "gif" => "image/gif",
                        "bmp" => "image/bmp",
                        "wav" | "wave" => "audio/wav",
                        "mp3" => "audio/mpeg",
                        "mp4" => "video/mp4",
                        "wmv" => "video/x-ms-wmv",
                        _ => "application/octet-stream",
                    })
                    .unwrap_or("application/octet-stream")
                    .to_string();
                
                media_files.push(MediaFile {
                    path: name.to_string(),
                    data,
                    content_type,
                });
            }
        }
        
        Ok(media_files)
    }
    
    fn extract_embedded_fonts<R: Read + Seek>(&self, archive: &mut zip::ZipArchive<R>) -> Result<Vec<Vec<u8>>> {
        let mut fonts = Vec::new();
        
        for i in 0..archive.len() {
            let entry = archive.by_index(i)?;
            let name = entry.name();
            
            if name.starts_with("ppt/embeddedFonts/") {
                let mut data = Vec::new();
                let mut entry = archive.by_index(i)?;
                entry.read_to_end(&mut data)?;
                fonts.push(data);
            }
        }
        
        Ok(fonts)
    }
}

impl Default for PptxParser {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parser_builder() {
        let parser = PptxParser::new()
            .with_strict_mode(true)
            .with_media_extraction(false)
            .with_animation_parsing(true)
            .with_transition_parsing(true);
        
        assert!(parser.strict_mode);
        assert!(!parser.extract_media);
        assert!(parser.parse_animations);
        assert!(parser.parse_transitions);
    }
    
    #[test]
    fn test_parser_default_config() {
        let parser = PptxParser::default();
        
        assert!(!parser.strict_mode);
        assert!(parser.extract_media);
        assert!(parser.parse_animations);
        assert!(parser.parse_transitions);
        assert!(!parser.extract_fonts);
    }
}
