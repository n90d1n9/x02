mod memory;
mod store;

pub use memory::InMemoryOfficeStore;
pub use store::{
    OfficeDocumentPersistMode, OfficeDocumentPersistReceipt, OfficeDocumentStore,
    OfficeOperationLogStore, OfficeSnapshotStore, OfficeStore,
};

#[cfg(test)]
mod tests;
