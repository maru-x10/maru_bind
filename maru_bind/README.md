# maru_bind

A dynamic keybinding system for FiveM (Qbox/ox_lib) that allows players to bind commands and events to keys in-game.

## Features

- **In-game UI**: Intuitive menu using `ox_lib`.
- **Diverse Actions**: Supports executing commands, triggering client events, and triggering server events.
- **Persistent Storage**: Saved locally using `Client KVP`, ensuring settings persist across sessions.
- **Flexible Rebinding**: Uses `RegisterKeyMapping`, allowing players to rebind keys later via the **GTA V Settings > Key Bindings > FiveM** menu.
- **Multi-language Support**: Locale support for English and Japanese.

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)

## Installation

1. Place the `maru_bind` folder in your `resources` directory.
2. Add the following to your `server.cfg`:
   ```cfg
   ensure ox_lib
   ensure maru_bind
   ```
3. (Optional) Set your preferred language in `fxmanifest.lua` or via `setr ox:locale "en"` in your server config.

## Usage

1. Type `/keybind` in the chat or console.
2. Select "Create New Keybind".
3. Fill in the details:
   - **Title**: A label for management (e.g., Use Medkit)
   - **Key**: The desired key (e.g., F5, K, LCONTROL)
   - **Action Type**: Command / Client Event / Server Event
   - **Action**: The actual command or event name (e.g., healme, ox_inventory:useItem)

## Notes

- When registering a command, a leading `/` is optional.
- To completely remove a deleted keybind's internal command registration, a client restart is required (though the functionality is disabled immediately).
- **Key Rebinding**: Once a bind is created, it will appear in the GTA V Key Bindings menu. If you want to change the key without deleting the bind, you can do it there.

## License

MIT
