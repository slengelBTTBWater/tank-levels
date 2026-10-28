# Tank Levels – Brady Township Troutville Borough Water Association

A public web page showing the water level in each storage tank. Every 15 minutes
GitHub pulls the latest readings from Zonelog and republishes the page.

## Files

| File | What it is |
|---|---|
| `index.html` | The public page |
| `logo.png` | Association logo shown at the top of the page |
| `tank-data.js` | Latest readings. Written automatically — don't edit by hand |
| `tanks.json` | Tank names, Zonelog logger serials, full heights. **Edit this one** |
| `scripts/update-tanks.mjs` | Fetches readings from the Zonelog API |
| `.github/workflows/update-tanks.yml` | Runs the updater every 15 minutes and publishes the page |

The Zonelog credentials are **never** stored in these files. They live in
GitHub's encrypted secrets (step 3).

## One-time setup

### 1. Create the GitHub account
Sign up at https://github.com/signup with **slengel@bttbwater.org**. Pick a
username such as `bttbwater` (it appears in the backup address
`https://<username>.github.io/tank-levels/`).

### 2. Create the repository and upload the files
1. Click **+ → New repository**. Name it `tank-levels`, choose **Public**
   (free GitHub Pages needs a public repository — no secrets are in the files),
   and click **Create repository**.
2. Click **uploading an existing file**, then drag in `index.html`,
   `logo.png`, `tank-data.js`, `tanks.json`, `README.md`, and the `scripts` and `.github`
   folders. Click **Commit changes**.
   - Check that `.github/workflows/update-tanks.yml` shows up in the repository.
     If Windows hid the `.github` folder, use **Add file → Create new file**,
     type `.github/workflows/update-tanks.yml` as the name, and paste the
     file's contents.

### 3. Add the Zonelog credentials
Go to **Settings → Secrets and variables → Actions → New repository secret**
and add these three, using the values Gutermann emailed you:

| Name | Value |
|---|---|
| `ZONELOG_CLIENT_ID` | OAuth Client ID |
| `ZONELOG_CLIENT_SECRET` | OAuth Client Secret |
| `ZONELOG_COMPANY_GUID` | API Key / Company GUID |

### 4. Turn on GitHub Pages
**Settings → Pages → Build and deployment → Source: GitHub Actions.**

### 5. Run it once
**Actions → Update tank levels → Run workflow.** After about a minute it
should show a green check. Open the **Fetch readings from Zonelog** step; it
lists each logger's latest reading, e.g.
`Logger 1957: 96 readings; latest 35.0 ftH2O (channel P1) at ...`.
The page is now live at `https://<username>.github.io/tank-levels/`.

### 6. Use your own address (tanks.bttbwater.org)
1. In GitHub: **Settings → Pages → Custom domain**, enter `tanks.bttbwater.org`, Save.
2. In Network Solutions, open bttbwater.org's DNS settings (labelled
   something like **Manage DNS** or **Advanced DNS**) and add a **CNAME record**:
   - Alias / Host: `tanks`
   - Points to: `<username>.github.io`
3. Wait for DNS (usually under an hour, up to 24), then back in GitHub Pages
   tick **Enforce HTTPS**.

## Everyday changes

**A new sensor is installed:** edit `tanks.json` on GitHub (pencil icon), remove
`"installing": true` from that tank, set `"capacity_ft"` to the tank's full
height in feet, and commit. The page updates within a minute.

**Post a notice** (e.g. a boil-water advisory): set `"notice"` in `tanks.json`
to the message; set it back to `""` to remove it.

**Change Low / Critical levels:** add `"low_pct": 60` and/or
`"critical_pct": 30` to a tank in `tanks.json`. Defaults are 60% and 30%.

## If something goes wrong

- GitHub emails slengel@bttbwater.org when a run fails. The page keeps showing
  the last good reading, and marks a tank **May be out of date** once its
  reading is over 6 hours old.
- A 401 error in the log means the credentials are wrong or expired. Update the
  secrets in step 3.
- GitHub's 15-minute schedule can run a few minutes late at busy times.
- GitHub pauses scheduled runs in repositories with no activity for 60 days.
  The updater saves each new reading to the repository, which counts as
  activity, so this shouldn't happen while it's working.
