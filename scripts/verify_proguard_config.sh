#!/bin/bash
# Verify ProGuard configuration is correct
# This script checks that all necessary ProGuard rules are in place
# to prevent the "Missing type parameter" notification crash

set -e

echo "======================================"
echo "ProGuard Configuration Verification"
echo "======================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}ERROR: Not in Flutter project root directory!${NC}"
    echo "Please run this script from the Flutter project root directory."
    exit 1
fi

echo "1. Checking ProGuard rules file exists..."
if [ ! -f "android/app/proguard-rules.pro" ]; then
    echo -e "${RED}✗ ERROR: proguard-rules.pro not found!${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ ProGuard rules file exists${NC}"
fi

echo ""
echo "2. Checking for critical TypeToken rule..."
if ! grep -q "com.google.gson.reflect.TypeToken" android/app/proguard-rules.pro; then
    echo -e "${RED}✗ ERROR: Critical TypeToken rule missing!${NC}"
    echo "  This rule is REQUIRED to prevent 'Missing type parameter' crashes."
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ TypeToken rule present${NC}"
fi

echo ""
echo "3. Checking for TypeToken subclass rule..."
if ! grep -q "extends com.google.gson.reflect.TypeToken" android/app/proguard-rules.pro; then
    echo -e "${RED}✗ ERROR: TypeToken subclass rule missing!${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ TypeToken subclass rule present${NC}"
fi

echo ""
echo "4. Checking for Signature attribute preservation..."
if ! grep -q "keepattributes Signature" android/app/proguard-rules.pro; then
    echo -e "${RED}✗ ERROR: -keepattributes Signature missing!${NC}"
    echo "  This is CRITICAL for preserving generic type information."
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Signature attributes will be preserved${NC}"
fi

echo ""
echo "5. Checking for Annotation attribute preservation..."
if ! grep -q "keepattributes.*Annotation" android/app/proguard-rules.pro; then
    echo -e "${YELLOW}⚠ WARNING: -keepattributes *Annotation* missing${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ Annotation attributes will be preserved${NC}"
fi

echo ""
echo "6. Checking build.gradle.kts for explicit minifyEnabled..."
if ! grep -q "isMinifyEnabled = true" android/app/build.gradle.kts; then
    echo -e "${YELLOW}⚠ WARNING: isMinifyEnabled not explicitly set to true${NC}"
    echo "  While R8 is enabled by default, explicit configuration is recommended."
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ Code minification explicitly enabled${NC}"
fi

echo ""
echo "7. Checking for ProGuard files reference in build.gradle.kts..."
if ! grep -q "proguardFiles" android/app/build.gradle.kts; then
    echo -e "${RED}✗ ERROR: proguardFiles not configured in build.gradle.kts!${NC}"
    ERRORS=$((ERRORS + 1))
else
    if grep -q "proguard-rules.pro" android/app/build.gradle.kts; then
        echo -e "${GREEN}✓ ProGuard rules file referenced in build config${NC}"
    else
        echo -e "${RED}✗ ERROR: proguard-rules.pro not referenced in proguardFiles!${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo ""
echo "8. Checking flutter_local_notifications version..."
FLN_VERSION=$(grep "flutter_local_notifications:" pubspec.yaml | sed 's/.*: *\^//' | sed 's/ .*//')
if [ -z "$FLN_VERSION" ]; then
    echo -e "${YELLOW}⚠ WARNING: Could not determine flutter_local_notifications version${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo "  Version: ^$FLN_VERSION"
    # Check if version is >= 19.0.0 (where ProGuard rules are built-in)
    MAJOR_VERSION=$(echo "$FLN_VERSION" | cut -d. -f1)
    if [ "$MAJOR_VERSION" -ge 19 ]; then
        echo -e "${YELLOW}⚠ INFO: Version 19+ includes ProGuard rules automatically${NC}"
        echo "  Consider removing local rules if not maintaining backward compatibility."
    else
        echo -e "${GREEN}✓ Version < 19 requires local ProGuard rules (currently configured)${NC}"
    fi
fi

echo ""
echo "9. Checking AndroidManifest.xml for notification receivers..."
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ ! -f "$MANIFEST" ]; then
    echo -e "${RED}✗ ERROR: AndroidManifest.xml not found!${NC}"
    ERRORS=$((ERRORS + 1))
else
    if grep -q "ScheduledNotificationReceiver" "$MANIFEST"; then
        echo -e "${GREEN}✓ ScheduledNotificationReceiver declared${NC}"
    else
        echo -e "${RED}✗ ERROR: ScheduledNotificationReceiver not declared in manifest!${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "ActionBroadcastReceiver" "$MANIFEST"; then
        echo -e "${GREEN}✓ ActionBroadcastReceiver declared${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING: ActionBroadcastReceiver not declared in manifest${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q "ScheduledNotificationBootReceiver" "$MANIFEST"; then
        echo -e "${GREEN}✓ ScheduledNotificationBootReceiver declared${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING: ScheduledNotificationBootReceiver not declared${NC}"
        echo "  Notifications may not reschedule after device reboot."
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
echo "10. Checking for GSON TypeAdapter rules..."
if ! grep -q "extends com.google.gson.TypeAdapter" android/app/proguard-rules.pro; then
    echo -e "${YELLOW}⚠ WARNING: TypeAdapter keep rule missing${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ TypeAdapter classes will be preserved${NC}"
fi

echo ""
echo "======================================"
echo "Verification Results"
echo "======================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "ProGuard configuration is correct and complete."
    echo "The 'Missing type parameter' crash should not occur."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Configuration is functional but could be improved."
    echo "Review warnings above and consider addressing them."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "CRITICAL ISSUES DETECTED!"
    echo "The 'Missing type parameter' crash WILL occur in release builds."
    echo "Please fix the errors above before releasing."
    exit 1
fi
