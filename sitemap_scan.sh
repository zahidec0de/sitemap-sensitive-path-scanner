#!/bin/bash

domain=$1
flag=$2

VERBOSE=false
if [[ "$flag" == "-v" ]]; then
    VERBOSE=true
fi

log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

if [ -z "$domain" ]; then
    echo "Usage: $0 <domain> [-v]"
    exit 1
fi

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
NC="\033[0m"

clear
echo -e "${BLUE}========================================================="
echo -e "                 Sensitive Sitemap Path Scanner"
echo -e "                 Domain: $domain"
echo -e "                 Author: zahidec0de"
echo -e "                 Verbose: $VERBOSE"
echo -e "                 Version: 1.0"
echo -e "=========================================================${NC}"
echo

# 1. SITEMAP DISCOVERY
sitemap_candidates=(
    "/sitemap_index.xml"
    "/sitemap.xml"
    "/wp-sitemap.xml"
    "/sitemap1.xml"
    "/sitemap-1.xml"
    "/default-sitemap.xml"
)

hosts=(
    "https://$domain"
    "https://www.$domain"
    "http://$domain"
    "http://www.$domain"
)

found_sitemaps=()

echo -e "${YELLOW}[+] STEP 1: Detecting available sitemap files...${NC}"
echo

for host in "${hosts[@]}"; do
    log "Testing host: $host"

    for path in "${sitemap_candidates[@]}"; do
        url="$host$path"
        log "Trying: $url"

        body=$(curl -s -L "$url" | head -n 5)

        log "Response first lines: $(echo "$body" | tr '\n' ' ' | cut -c1-120)"

        # Skip HTML/WAF pages
        if echo "$body" | grep -qi "<html"; then
            log "HTML detected — skipping"
            continue
        fi

        # Valid XML sitemap detected
        if echo "$body" | grep -qi "<?xml"; then
            echo -e "  ${GREEN}[FOUND]${NC} $url"
            found_sitemaps+=("$url")
        fi

    done
done

if [ ${#found_sitemaps[@]} -eq 0 ]; then
    echo -e "${RED}[!] No sitemap found.${NC}"
    exit 0
fi

echo
echo -e "${GREEN}[✓] Found ${#found_sitemaps[@]} sitemap file(s).${NC}"
echo

# 2. SAFE FILENAMES (AUTO SKIPPED ALWAYS)
safe_sitemaps=(
    "sitemap.xml"
    "sitemap-cms.xml"
    "cms-sitemap.xml"
    "sitemap-pages.xml"
    "sitemap-posts.xml"
    "sitemap-tags.xml"
    "sitemap-products.xml"
    "sitemap-categories.xml"
    "post-sitemap.xml"
    "post-sitemap1.xml"
    "post-sitemap2.xml"
    "post-sitemap3.xml"
    "post-sitemap4.xml"
    "page-sitemap.xml"
    "category-sitemap.xml"
    "post_tag-sitemap.xml"
    "fusion_tb_category-sitemap.xml"
    "college-sitemap.xml"
    "announcement_category-sitemap.xml"
    "important_date_category-sitemap.xml"
    "tribe_events-sitemap.xml"
    "tribe_events_cat-sitemap.xml"
    "element_category-sitemap.xml"
)

# 3. SENSITIVE KEYWORDS(URL PATHS ONLY)
sensitive_keywords="admin|administrator|adminpanel|admin_area|adminarea|root|superuser|
dashboard|manage|management|manager|userpanel|account|auth|authentication|authorize|
login|signin|sign_in|sign-on|verify|access|restricted_access|portal|
debug|debugger|debugmode|xdebug|phpinfo|info\.php|server-status|status\.php|
diagnostics|profiler|stacktrace|stack_trace|trace|tracing|errors|exceptions|
php-errors|php_error|error_log|devtools|devel|developer|development|
test|testing|qa|uat|staging|stage|preprod|pre-production|preview|sandbox|
beta|alpha|experiment|experiments|trial|demo|prototype|draft|temp|temporary|
internal|private|hidden|backend|secret_area|restricted|confidential|
intranet|sysadmin|system|sys|secure_area|securezone|members|staff-only|ops|
operations|partner|vendor_portal|supplier_portal|
backup|backups|bak|old|archive|archived|archives|zip|tar|gz|gzip|7z|rar|
dump|dumped|sql|mysql_dump|db_dump|database_backup|copy|clone|snapshot|
log|logs|logging|error|errors|eventlog|event-log|syslog|metrics|monitor|
monitoring|health|healthcheck|health-status|server-health|reports|reporting|
analytics|stats|
db|database|sql|mysql|mssql|oracle|postgres|pg|sqlite|env|environment|
credentials|cred|password|passwd|pw|token|api_token|secret|key|keys|config|
configuration|settings|phpmyadmin|adminer|dbadmin|redis|mongo|
wp-admin|wp-login|wp-json|xmlrpc\.php|joomla|drupal|cms\/admin|cms\/login|
cms\/dashboard|cms\/manage|laravel|magento|symfony|typo3|sitecore|strapi|
cockpit|umbraco|ghost|directus|craftcms|prestashop|opencart|bigcommerce|
shopify_admin|
api|rest|graphql|rpc|soap|endpoint|endpoints|wsdl|swagger|v1|v2|v3|
session|jwt|access_token|refresh_token|callback|webhook|
reset|forgot_password|forgot|pwreset|change-password|token-verify|
session-debug|session-info|sessionid|session_id|
security|firewall|waf|modsec|modsecurity|scan|scanner|server-info|
ctf|challenge|lab|training|exercises|exam|practice|debugfolder|internalapp|
oldsite|legacy|legacyapp|beta_site"

# 4. SCANNING BEGINS
echo -e "${BLUE}========================================================="
echo -e "           STEP 2: Scanning for Sensitive Paths"
echo -e "=========================================================${NC}"
echo

for sitemap in "${found_sitemaps[@]}"; do

    sm_name=$(basename "$sitemap")

    echo -e "${YELLOW}[+] Checking: $sitemap${NC}"
    echo

    urls=$(curl -s -L "$sitemap" | grep -oP '(?<=<loc>)[^<]+')

    if [ -z "$urls" ]; then
        echo "  No URLs found."
        echo "-------------------------------------------------------------"
        echo
        continue
    fi

    sensitive_found=false

    while read -r url; do
        log "Scanning URL: $url"

        # Skip SAFE filenames completely
        for safe in "${safe_sitemaps[@]}"; do
            if [[ "$url" == *"$safe" ]]; then
                log "Skipping safe sitemap file: $url"
                continue 2
            fi
        done

        # Perform sensitive keyword detection (in actual path only)
        match=$(echo "$url" | grep -oiE "$sensitive_keywords")

        if [ ! -z "$match" ]; then
            sensitive_found=true

            echo -e "  ${RED}Sensitive Path Found:${NC}"
            echo -e "      URL:       $url"
            echo
        fi

    done <<< "$urls"

    if [ "$sensitive_found" = false ]; then
        echo -e "  ${GREEN}✓ SAFE:${NC} No sensitive URLs found in this sitemap."
    fi

    echo "-------------------------------------------------------------"
    echo
done

echo -e "${GREEN}[*] Scan completed successfully.${NC}"
