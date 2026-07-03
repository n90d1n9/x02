#[derive(Debug, Clone, PartialEq)]
pub enum DrawCommand {
    Save,
    Restore,
    Translate { x: f64, y: f64 },
}

#[derive(Debug, Clone, Default, PartialEq)]
pub struct DrawCommandList {
    commands: Vec<DrawCommand>,
}

impl DrawCommandList {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn push(&mut self, command: DrawCommand) {
        self.commands.push(command);
    }

    pub fn as_slice(&self) -> &[DrawCommand] {
        &self.commands
    }

    pub fn len(&self) -> usize {
        self.commands.len()
    }

    pub fn is_empty(&self) -> bool {
        self.commands.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn records_draw_commands_in_order() {
        let mut commands = DrawCommandList::new();
        commands.push(DrawCommand::Save);
        commands.push(DrawCommand::Translate { x: 12.0, y: 24.0 });
        commands.push(DrawCommand::Restore);

        assert_eq!(
            commands.as_slice(),
            &[
                DrawCommand::Save,
                DrawCommand::Translate { x: 12.0, y: 24.0 },
                DrawCommand::Restore
            ]
        );
    }
}
