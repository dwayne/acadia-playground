# Acadia Playground

A playground for me to explore [Acadia](https://acadia.engineering/) and [Elm](https://elm-lang.org/).

## Prerequisites

- [Nix](https://zero-to-nix.com/start/install/)
- Linux x64

## Usage

```bash
nix develop

# Serve examples/01-foods
s1

# Serve examples/02-origin
s2

# Serve examples/03-users
s3

# Serve todos
st
```

## Highlights

### Acadia and Elm dependencies managed with Nix

In the [nix](/nix) folder you'd find Nix derivations for Acadia 0.3.0 and Elm 0.19.2. I've only added support for `system = "x86_64-linux"`.

### Examples managed as a flake input

To test that everything worked I added the [`acadia-engineering/examples`](https://github.com/acadia-engineering/examples) as a flake input in [`flake.nix`](/flake.nix)

```nix
inputs.acadia-engineering-examples = {
  url = "github:acadia-engineering/examples";
  flake = false;
};
```

in order to vendor them in this project. When the examples are updated I can do the following:

1. Remove the `examples` folder.
2. Run `nix flake update acadia-engineering-examples` to update the revision that the lock file points to.
3. Reload the developer shell.

### Elm Todos on Acadia

I updated [my implementation](https://github.com/dwayne/elm-todos) of the TodoMVC application to work with Acadia and save its data to a SQLite database instead of localStorage.

The change was easy to make, it works well but two features couldn't be implemented properly since **you currently cannot [update](https://acadia.engineering/documentation/Table#update)/[remove](https://acadia.engineering/documentation/Table#remove) multiple rows in a single transaction**.

Evan says:

> ... need to add it. Adding “SQL features” is very easy, so I didn’t block on that.

### Quirks of todos

I wasn't able to get `acadia serve` to serve my HTML file and link to an external stylesheet or JavaScript file. Since the CSS doesn't change I just inlined it into the HTML file for now. However, the JavaScript changes more often. To get it working I generate the `app.js` file as usual using `elm make` but then I use `sed` to copy the contents of `app.js` into a delimited section of the `index.html` file. See `serve-todos` and `replace-with-contents-of-app-js` in [`flake.nix`](/flake.nix) for more details.
