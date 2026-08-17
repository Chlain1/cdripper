# cdripper
Automation of extracting the Audio Files from a CD, ejecting the CD-Trace and waiting for another CD

## Requirenments
For the script to work, we need this dotnet tool, that calculates the hash of the MusicBrainz Disc ID
```bash
dotnet tool install -g MetaBrainz.MusicBrainz.dotnet-mbdiscid
```

## Running the Script
```bash
bash cdripper.sh
```