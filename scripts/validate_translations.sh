#!/bin/bash

# Translation validation script for Aquarium AI
# This script checks ARB translation files for completeness and correctness

set -e

echo "🌍 Aquarium AI Translation Validator"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TEMPLATE="lib/l10n/app_en.arb"
ERRORS=0
WARNINGS=0

# Check if template exists
if [ ! -f "$TEMPLATE" ]; then
    echo -e "${RED}❌ Error: Template file $TEMPLATE not found${NC}"
    exit 1
fi

echo "📋 Template file: $TEMPLATE"
echo ""

# Get all translation keys from template
TEMPLATE_KEYS=$(grep -o '"[a-zA-Z][a-zA-Z0-9_]*"' "$TEMPLATE" | grep -v '"@@' | sort | uniq)
TEMPLATE_COUNT=$(echo "$TEMPLATE_KEYS" | wc -l)

echo "📊 Template contains $TEMPLATE_COUNT keys"
echo ""

# Check each translation file
for TRANS_FILE in lib/l10n/app_*.arb; do
    if [ "$TRANS_FILE" = "$TEMPLATE" ]; then
        continue
    fi
    
    LANG=$(basename "$TRANS_FILE" .arb | sed 's/app_//')
    echo "🔍 Checking $LANG translation ($TRANS_FILE)..."
    
    # Check if file is valid JSON
    if ! python3 -m json.tool "$TRANS_FILE" > /dev/null 2>&1; then
        echo -e "  ${RED}❌ Invalid JSON syntax${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi
    
    # Get translation keys
    TRANS_KEYS=$(grep -o '"[a-zA-Z][a-zA-Z0-9_]*"' "$TRANS_FILE" | grep -v '"@@' | sort | uniq)
    TRANS_COUNT=$(echo "$TRANS_KEYS" | wc -l)
    
    # Check for missing keys
    MISSING_KEYS=0
    while IFS= read -r KEY; do
        if ! echo "$TRANS_KEYS" | grep -q "$KEY"; then
            if [ $MISSING_KEYS -eq 0 ]; then
                echo -e "  ${YELLOW}⚠️  Missing keys:${NC}"
            fi
            echo "     - $(echo $KEY | tr -d '"')"
            MISSING_KEYS=$((MISSING_KEYS + 1))
            WARNINGS=$((WARNINGS + 1))
        fi
    done <<< "$TEMPLATE_KEYS"
    
    # Check for extra keys (not in template)
    EXTRA_KEYS=0
    while IFS= read -r KEY; do
        if ! echo "$TEMPLATE_KEYS" | grep -q "$KEY"; then
            if [ $EXTRA_KEYS -eq 0 ]; then
                echo -e "  ${YELLOW}⚠️  Extra keys (not in template):${NC}"
            fi
            echo "     + $(echo $KEY | tr -d '"')"
            EXTRA_KEYS=$((EXTRA_KEYS + 1))
            WARNINGS=$((WARNINGS + 1))
        fi
    done <<< "$TRANS_KEYS"
    
    # Check for placeholder consistency
    echo "  🔤 Checking placeholders..."
    PLACEHOLDER_ISSUES=0
    while IFS= read -r KEY; do
        KEY_NAME=$(echo $KEY | tr -d '"')
        
        # Get value from template
        TEMPLATE_VALUE=$(grep "\"$KEY_NAME\":" "$TEMPLATE" | sed 's/.*: "\(.*\)".*/\1/' || true)
        TEMPLATE_PLACEHOLDERS=$(echo "$TEMPLATE_VALUE" | grep -o '{[^}]*}' || true)
        
        # Get value from translation
        TRANS_VALUE=$(grep "\"$KEY_NAME\":" "$TRANS_FILE" | sed 's/.*: "\(.*\)".*/\1/' || true)
        TRANS_PLACEHOLDERS=$(echo "$TRANS_VALUE" | grep -o '{[^}]*}' || true)
        
        # Compare placeholders
        if [ "$TEMPLATE_PLACEHOLDERS" != "$TRANS_PLACEHOLDERS" ]; then
            if [ -n "$TEMPLATE_PLACEHOLDERS" ] || [ -n "$TRANS_PLACEHOLDERS" ]; then
                if [ $PLACEHOLDER_ISSUES -eq 0 ]; then
                    echo -e "  ${YELLOW}⚠️  Placeholder mismatches:${NC}"
                fi
                echo "     • $KEY_NAME"
                echo "       Template: $TEMPLATE_PLACEHOLDERS"
                echo "       Translation: $TRANS_PLACEHOLDERS"
                PLACEHOLDER_ISSUES=$((PLACEHOLDER_ISSUES + 1))
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done <<< "$TEMPLATE_KEYS"
    
    # Summary for this language
    echo ""
    echo "  📈 Summary for $LANG:"
    echo "     Keys in template: $TEMPLATE_COUNT"
    echo "     Keys in translation: $TRANS_COUNT"
    
    if [ $MISSING_KEYS -eq 0 ] && [ $EXTRA_KEYS -eq 0 ] && [ $PLACEHOLDER_ISSUES -eq 0 ]; then
        echo -e "  ${GREEN}✅ All checks passed!${NC}"
    else
        if [ $MISSING_KEYS -gt 0 ]; then
            echo -e "     ${YELLOW}Missing: $MISSING_KEYS${NC}"
        fi
        if [ $EXTRA_KEYS -gt 0 ]; then
            echo -e "     ${YELLOW}Extra: $EXTRA_KEYS${NC}"
        fi
        if [ $PLACEHOLDER_ISSUES -gt 0 ]; then
            echo -e "     ${YELLOW}Placeholder issues: $PLACEHOLDER_ISSUES${NC}"
        fi
    fi
    
    echo ""
done

# Final summary
echo "===================================="
echo "📊 Final Summary"
echo "===================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All translations are valid!${NC}"
    exit 0
else
    if [ $ERRORS -gt 0 ]; then
        echo -e "${RED}❌ Errors: $ERRORS${NC}"
    fi
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
    fi
    
    if [ $ERRORS -gt 0 ]; then
        exit 1
    else
        echo ""
        echo -e "${YELLOW}Note: Warnings don't prevent the app from running,${NC}"
        echo -e "${YELLOW}but fixing them will improve translation completeness.${NC}"
        exit 0
    fi
fi
