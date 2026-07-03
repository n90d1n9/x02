use super::model::OperationTransaction;
use crate::OperationEnvelope;

pub trait OperationApplier<T> {
    type Outcome;
    type Error;

    fn apply_operation(
        &mut self,
        operation: OperationEnvelope<T>,
    ) -> Result<Self::Outcome, Self::Error>;
}

pub fn apply_operations<T, A, I>(
    applier: &mut A,
    operations: I,
) -> Result<Vec<A::Outcome>, A::Error>
where
    A: OperationApplier<T>,
    I: IntoIterator<Item = OperationEnvelope<T>>,
{
    operations
        .into_iter()
        .map(|operation| applier.apply_operation(operation))
        .collect()
}

pub fn apply_transaction<T, A>(
    applier: &mut A,
    transaction: &OperationTransaction<T>,
) -> Result<Vec<A::Outcome>, A::Error>
where
    T: Clone,
    A: OperationApplier<T>,
{
    apply_operations(applier, transaction.operations.iter().cloned())
}
