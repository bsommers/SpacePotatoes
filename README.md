# Space Potatoes

A single-file HTML5 canvas game. You're a Space Cat defending HOME BASE from incoming space potatoes.

## Play

Open `index.html` in a browser. No build step or dependencies.

## Modes

- **Classic**: swat purple space potatoes before they reach the cat. Big potatoes split into chunks.
- **🌶 Spicy**: the potatoes turn red-hot, and you also face:
  - **Hot sauce shooters**: turrets that orbit the cat and fire hot sauce blobs or chillies. Swat for 15 points.
  - **Chilli peppers**: they fly in from the edges and hurt on contact. Swat them for 8 points and +20 milk.
  - **Milk shield**: hold **Space** or **right-click** to block sauce, chillies and potatoes. It drains while held and refills while down.

## Controls

| Action | Input |
| --- | --- |
| Aim | Mouse |
| Swat | Left-click (within swat range) |
| Milk shield (Spicy) | Hold Space or right mouse button |

## Repositories

- **Upstream (authoritative):** `bsommers/SpacePotatoes`. Commit and push here.
- **Origin (org mirror):** `spicyspacepotatoes/SpacePotatoes`.

`scripts/sync_repo.sh` pulls from upstream and pushes to the org. It is the same script flowscope uses, with a different config block.

```sh
./scripts/sync_repo.sh            # pull from upstream, push to origin
./scripts/sync_repo.sh --status   # compare local, upstream and origin
./scripts/sync_repo.sh --dry-run  # preview only
```

## License

Licensed under the [Apache License 2.0](LICENSE).
