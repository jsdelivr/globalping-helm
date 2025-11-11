#!/bin/bash
# Script to validate the Helm chart structure and content

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

CHART_DIR="charts/globalping-probe"
ERRORS=0

# Check chart directory exists
if [ ! -d "$CHART_DIR" ]; then
    print_error "Chart directory not found: $CHART_DIR"
    exit 1
fi

print_info "Validating chart structure..."

# Check required files
REQUIRED_FILES=(
    "Chart.yaml"
    "values.yaml"
    "README.md"
    ".helmignore"
    "templates/_helpers.tpl"
    "templates/NOTES.txt"
    "templates/daemonset.yaml"
    "templates/deployment.yaml"
    "templates/secret.yaml"
    "templates/serviceaccount.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$CHART_DIR/$file" ]; then
        print_status "$file exists"
    else
        print_error "$file is missing"
        ((ERRORS++))
    fi
done

# Validate Chart.yaml
print_info "Validating Chart.yaml..."

if grep -q "^name:" "$CHART_DIR/Chart.yaml"; then
    print_status "Chart name defined"
else
    print_error "Chart name missing"
    ((ERRORS++))
fi

if grep -q "^version:" "$CHART_DIR/Chart.yaml"; then
    print_status "Chart version defined"
else
    print_error "Chart version missing"
    ((ERRORS++))
fi

if grep -q "^apiVersion: v2" "$CHART_DIR/Chart.yaml"; then
    print_status "API version v2"
else
    print_error "API version should be v2"
    ((ERRORS++))
fi

if grep -q "artifacthub.io" "$CHART_DIR/Chart.yaml"; then
    print_status "Artifact Hub annotations present"
else
    print_error "Artifact Hub annotations missing"
    ((ERRORS++))
fi

# Validate values.yaml
print_info "Validating values.yaml..."

if grep -q "globalpingToken:" "$CHART_DIR/values.yaml"; then
    print_status "globalpingToken parameter present"
else
    print_error "globalpingToken parameter missing"
    ((ERRORS++))
fi

if grep -q "deploymentType:" "$CHART_DIR/values.yaml"; then
    print_status "deploymentType parameter present"
else
    print_error "deploymentType parameter missing"
    ((ERRORS++))
fi

if grep -q "hostNetwork:" "$CHART_DIR/values.yaml"; then
    print_status "hostNetwork parameter present"
else
    print_error "hostNetwork parameter missing"
    ((ERRORS++))
fi

# Validate templates
print_info "Validating template syntax..."

if command -v helm &> /dev/null; then
    if helm lint "$CHART_DIR" &> /dev/null; then
        print_status "Helm lint passed"
    else
        print_error "Helm lint failed"
        helm lint "$CHART_DIR"
        ((ERRORS++))
    fi
else
    print_error "Helm not installed, skipping lint"
fi

# Check for common issues
print_info "Checking for common issues..."

# Check for hardcoded values
if grep -r "TODO\|FIXME\|XXX" "$CHART_DIR/templates/" > /dev/null; then
    print_error "TODO/FIXME/XXX found in templates"
    grep -rn "TODO\|FIXME\|XXX" "$CHART_DIR/templates/"
    ((ERRORS++))
else
    print_status "No TODO/FIXME markers"
fi

# Check for proper indentation in templates
if grep -r "{{-" "$CHART_DIR/templates/" | grep -v "nindent\|indent" > /dev/null; then
    print_info "Some templates use trim without indent (this might be intentional)"
fi

# Validate YAML syntax
print_info "Validating YAML syntax..."

for yaml_file in "$CHART_DIR"/*.yaml "$CHART_DIR/templates"/*.yaml; do
    if [ -f "$yaml_file" ]; then
        if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
            print_status "$(basename $yaml_file) - valid YAML"
        else
            # Templates might not be valid YAML due to Go templates
            if [[ "$yaml_file" == *"/templates/"* ]]; then
                print_info "$(basename $yaml_file) - skipped (template file)"
            else
                print_error "$(basename $yaml_file) - invalid YAML"
                ((ERRORS++))
            fi
        fi
    fi
done

# Check README
print_info "Validating README..."

if [ -f "$CHART_DIR/README.md" ]; then
    if grep -q "Installation" "$CHART_DIR/README.md"; then
        print_status "README contains installation instructions"
    else
        print_error "README missing installation section"
        ((ERRORS++))
    fi
    
    if grep -q "Configuration" "$CHART_DIR/README.md"; then
        print_status "README contains configuration section"
    else
        print_error "README missing configuration section"
        ((ERRORS++))
    fi
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    print_status "Validation completed successfully! ✨"
    exit 0
else
    print_error "Validation failed with $ERRORS error(s)"
    exit 1
fi

