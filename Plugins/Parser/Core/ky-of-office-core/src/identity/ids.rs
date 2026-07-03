use serde::{Deserialize, Serialize};
use std::borrow::Borrow;
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum IdValidationError {
    Empty,
}

macro_rules! define_office_id {
    ($name:ident) => {
        #[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
        #[serde(transparent)]
        pub struct $name(String);

        impl $name {
            pub fn new(value: impl Into<String>) -> Self {
                Self(value.into())
            }

            pub fn try_new(value: impl Into<String>) -> Result<Self, IdValidationError> {
                let value = value.into();
                if value.trim().is_empty() {
                    return Err(IdValidationError::Empty);
                }

                Ok(Self(value))
            }

            pub fn as_str(&self) -> &str {
                &self.0
            }

            pub fn into_string(self) -> String {
                self.0
            }

            pub fn is_empty(&self) -> bool {
                self.0.is_empty()
            }
        }

        impl From<String> for $name {
            fn from(value: String) -> Self {
                Self::new(value)
            }
        }

        impl From<&str> for $name {
            fn from(value: &str) -> Self {
                Self::new(value)
            }
        }

        impl From<$name> for String {
            fn from(value: $name) -> Self {
                value.into_string()
            }
        }

        impl AsRef<str> for $name {
            fn as_ref(&self) -> &str {
                self.as_str()
            }
        }

        impl Borrow<str> for $name {
            fn borrow(&self) -> &str {
                self.as_str()
            }
        }

        impl fmt::Display for $name {
            fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
                formatter.write_str(self.as_str())
            }
        }

        impl PartialEq<&str> for $name {
            fn eq(&self, other: &&str) -> bool {
                self.as_str() == *other
            }
        }

        impl PartialEq<$name> for &str {
            fn eq(&self, other: &$name) -> bool {
                *self == other.as_str()
            }
        }

        impl PartialEq<String> for $name {
            fn eq(&self, other: &String) -> bool {
                self.as_str() == other
            }
        }

        impl PartialEq<$name> for String {
            fn eq(&self, other: &$name) -> bool {
                self == other.as_str()
            }
        }
    };
}

define_office_id!(EngineId);
define_office_id!(OperationId);
define_office_id!(DocumentId);
define_office_id!(ActorId);
define_office_id!(TransactionId);
define_office_id!(ObjectId);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ids_serialize_as_plain_strings() {
        let id = DocumentId::new("doc-1");
        let json = serde_json::to_string(&id).unwrap();
        let restored: DocumentId = serde_json::from_str(&json).unwrap();

        assert_eq!(json, "\"doc-1\"");
        assert_eq!(restored, "doc-1");
    }

    #[test]
    fn ids_validate_empty_values_when_requested() {
        assert_eq!(ActorId::try_new("  "), Err(IdValidationError::Empty));
        assert_eq!(ActorId::try_new("actor-1").unwrap(), "actor-1");
    }
}
