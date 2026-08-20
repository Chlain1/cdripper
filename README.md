# cdripper
Automation of extracting the Audio Files from a CD, ejecting the CD-Trace and waiting for another CD

## Requirenments
For the script to work, we need this dotnet tool, that calculates the hash of the MusicBrainz Disc ID
```bash
dotnet tool install -g MetaBrainz.MusicBrainz.dotnet-mbdiscid
```

You also need `ffmpeg` installed for MP3 encoding and writing metadata tags.

## Running the Script
```bash
bash cdripper.sh
```