#!/usr/bin/env bash

# LearnStories Dictionaries Release Script
# Creates a new versioned release with automatic GitHub Release creation

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
BUMP_TYPE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --type)
      BUMP_TYPE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 --type <major|minor|patch> [--dry-run]"
      exit 1
      ;;
  esac
done

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
  echo -e "${RED}Error: --type must be one of: major, minor, patch${NC}"
  exit 1
fi

echo -e "${BLUE}=== LearnStories Dictionaries Release Script ===${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check git
if ! command -v git &> /dev/null; then
  echo -e "${RED}Error: git is not installed${NC}"
  exit 1
fi

# Check jq
if ! command -v jq &> /dev/null; then
  echo -e "${RED}Error: jq is not installed. Install with: brew install jq${NC}"
  exit 1
fi

# Check gh CLI
if ! command -v gh &> /dev/null; then
  echo -e "${RED}Error: GitHub CLI is not installed. Install with: brew install gh${NC}"
  exit 1
fi

# Check gh authentication
if ! gh auth status &> /dev/null; then
  echo -e "${RED}Error: GitHub CLI is not authenticated. Run: gh auth login${NC}"
  exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  echo -e "${RED}Error: You have uncommitted changes. Please commit or stash them first.${NC}"
  git status --short
  exit 1
fi

# Check we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo -e "${YELLOW}Warning: You are not on main branch (current: $CURRENT_BRANCH)${NC}"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo -e "${GREEN}✓ All prerequisites met${NC}\n"

# Read current version
if [[ ! -f "version.json" ]]; then
  echo -e "${RED}Error: version.json not found${NC}"
  exit 1
fi

CURRENT_VERSION=$(jq -r '.version' version.json)
echo -e "${BLUE}Current version: ${CURRENT_VERSION}${NC}"

# Parse version
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Bump version
case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo -e "${GREEN}New version: ${NEW_VERSION}${NC}\n"

# Prompt for changelog entry
echo -e "${YELLOW}Enter changelog entry (what changed in this release):${NC}"
echo "Press Ctrl+D when done, Ctrl+C to cancel"
echo "---"
CHANGELOG_ENTRY=$(cat)
echo "---"

if [[ -z "$CHANGELOG_ENTRY" ]]; then
  echo -e "${RED}Error: Changelog entry cannot be empty${NC}"
  exit 1
fi

# Find all dictionary files
echo -e "\n${YELLOW}Finding dictionary files...${NC}"
DICT_FILES=($(find . -name "*.db" -type f | sort))

if [[ ${#DICT_FILES[@]} -eq 0 ]]; then
  echo -e "${RED}Error: No .db files found${NC}"
  exit 1
fi

echo -e "${GREEN}Found ${#DICT_FILES[@]} dictionary files:${NC}"
for file in "${DICT_FILES[@]}"; do
  SIZE=$(ls -lh "$file" | awk '{print $5}')
  echo "  - $file ($SIZE)"
done

# Calculate MD5 checksums
echo -e "\n${YELLOW}Calculating MD5 checksums...${NC}"
declare -A MD5_CHECKSUMS
for file in "${DICT_FILES[@]}"; do
  LANG=$(basename "$(dirname "$file")")
  MD5=$(md5 -q "$file")
  MD5_CHECKSUMS["$LANG"]="$MD5"
  echo "  - $LANG: $MD5"
done

# Update version.json
echo -e "\n${YELLOW}Updating version.json...${NC}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create temporary version.json with updated values
jq --arg version "$NEW_VERSION" \
   --arg timestamp "$TIMESTAMP" \
   '.version = $version | .publishedAt = $timestamp' \
   version.json > version.json.tmp

# Update each dictionary's version, URL, and MD5
for lang in "${!MD5_CHECKSUMS[@]}"; do
  MD5="${MD5_CHECKSUMS[$lang]}"
  jq --arg lang "$lang" \
     --arg version "$NEW_VERSION" \
     --arg md5 "$MD5" \
     --arg url "https://github.com/zyaga/learnstories-dictionaries/releases/download/v${NEW_VERSION}/${lang}.db" \
     --arg timestamp "$TIMESTAMP" \
     '.dictionaries[$lang].version = $version |
      .dictionaries[$lang].md5 = $md5 |
      .dictionaries[$lang].url = $url |
      .dictionaries[$lang].lastModified = $timestamp' \
     version.json.tmp > version.json.tmp2
  mv version.json.tmp2 version.json.tmp
done

mv version.json.tmp version.json
echo -e "${GREEN}✓ version.json updated${NC}"

# Update CHANGELOG.md
echo -e "\n${YELLOW}Updating CHANGELOG.md...${NC}"
CHANGELOG_DATE=$(date +"%Y-%m-%d")

# Create new changelog entry
NEW_ENTRY="## [${NEW_VERSION}] - ${CHANGELOG_DATE}\n\n### Changed\n${CHANGELOG_ENTRY}\n"

# Insert after [Unreleased] section
sed -i.bak "/## \[Unreleased\]/a\\
\\
$NEW_ENTRY" CHANGELOG.md
rm CHANGELOG.md.bak 2>/dev/null || true
echo -e "${GREEN}✓ CHANGELOG.md updated${NC}"

if [[ "$DRY_RUN" == true ]]; then
  echo -e "\n${YELLOW}=== DRY RUN - No changes committed ===${NC}"
  echo -e "Would create release: ${GREEN}v${NEW_VERSION}${NC}"
  echo -e "Would upload ${#DICT_FILES[@]} files"
  git diff version.json CHANGELOG.md
  git restore version.json CHANGELOG.md
  exit 0
fi

# Commit changes
echo -e "\n${YELLOW}Creating commit...${NC}"
git add version.json CHANGELOG.md
git commit -m "Release v${NEW_VERSION}

${CHANGELOG_ENTRY}"
echo -e "${GREEN}✓ Commit created${NC}"

# Create and push tag
echo -e "\n${YELLOW}Creating git tag...${NC}"
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
echo -e "${GREEN}✓ Tag created${NC}"

echo -e "\n${YELLOW}Pushing to GitHub...${NC}"
git push origin "$CURRENT_BRANCH"
git push origin "v${NEW_VERSION}"
echo -e "${GREEN}✓ Pushed to GitHub${NC}"

# Create GitHub Release
echo -e "\n${YELLOW}Creating GitHub Release...${NC}"
gh release create "v${NEW_VERSION}" \
  --title "v${NEW_VERSION}" \
  --notes "${CHANGELOG_ENTRY}" \
  "${DICT_FILES[@]}"

echo -e "${GREEN}✓ GitHub Release created${NC}"

# Verify release assets
echo -e "\n${YELLOW}Verifying release assets...${NC}"
sleep 2  # Give GitHub a moment to process

for file in "${DICT_FILES[@]}"; do
  LANG=$(basename "$(dirname "$file")")
  URL="https://github.com/zyaga/learnstories-dictionaries/releases/download/v${NEW_VERSION}/${LANG}.db"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL")

  if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "302" ]]; then
    echo -e "  ${GREEN}✓${NC} $LANG.db - $URL"
  else
    echo -e "  ${RED}✗${NC} $LANG.db - HTTP $HTTP_CODE"
  fi
done

echo -e "\n${GREEN}=== Release Complete! ===${NC}"
echo -e "${BLUE}Version:${NC} v${NEW_VERSION}"
echo -e "${BLUE}Tag:${NC} v${NEW_VERSION}"
echo -e "${BLUE}Release URL:${NC} https://github.com/zyaga/learnstories-dictionaries/releases/tag/v${NEW_VERSION}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Verify release on GitHub"
echo -e "2. Update app to use v${NEW_VERSION}"
echo -e "3. Test dictionary downloads in app"
