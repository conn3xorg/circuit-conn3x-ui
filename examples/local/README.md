# Local example

Applies circuit-conn3x-ui to a throwaway Rocky Linux 10 container with systemd. You need Conn3x and Podman.

```sh
./up.sh
conn3x init
conn3x apply
conn3x plan
```

The second plan says `No changes.` Then open <http://127.0.0.1:8080> and sign in as `admin` with the password from the UI's log:

```sh
podman exec circuit-conn3x-ui journalctl -u conn3x-ui | grep -i password
```

`up.sh` listens on `127.0.0.1:2222`, and forwards `127.0.0.1:8080` to the UI. Inside the container the UI listens on every address, so the forward reaches it; the forward itself stays on your machine. Set `PORT` to use another SSH port, and pass the same port to Conn3x with `-var port=PORT`. Set `UI_PORT` to move the other. Set `CONTAINERFILE` to test another distro, such as one of the images in Conn3x's `test/images`, which CI uses.

`./down.sh` removes the container, the key and the state.
