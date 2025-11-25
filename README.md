# sitemap-sensitive-path-scanner
Bash-based scanner that identifies sensitive or internal web paths exposed through public sitemap files. Designed for use in security assessments, EASM enumeration, red-team OSINT, and surface monitoring.

## What This Script Does

#### 1. Looks for sitemap files
It tries multiple common sitemap locations like:
  - /sitemap.xml
  - /sitemap_index.xml
  - /wp-sitemap.xml

#### 2. Reads every URL inside the sitemap
It extracts all <loc> links from the sitemap.

#### 3. Skips safe sitemap files
Many sitemap files are normal and safe, such as:
``sitemap-cms.xml``, ``page-sitemap.xml``, ``category-sitemap.xml``
The script automatically ignores them.

#### 4. Checks URLs for sensitive keywords
It looks for hundreds of sensitive keywords in the URL path

#### 5. Shows only real sensitive paths (default)
It does NOT flag sitemap filenames.
It ONLY flags real URLs that contain sensitive patterns.

#### 6. Outputs clean results
Only the URLs that need attention are displayed.

#### 7. Verbose mode (optional)
Add ``-v`` to show debug logs.

## How to Use
#### 1. Clone the repository
```git clone ....```

#### 2. Make the bash file executable
```./sitemap_scan.sh example.com```

#### 3. Scan a domain 
```./sitemap_scan.sh example.com```

#### 4. Debug mode
```./sitemap_scan.sh example.com -v```

## Contributing
All contributions are welcome.
You may add new keywords, improve scanning, or extend functionality.

