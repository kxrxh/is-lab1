#!/bin/bash

# Secure API Testing Script
# This script tests all endpoints of the Secure API application

BASE_URL="http://localhost:8080"
TOKEN=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}✗ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ $message${NC}"
            ;;
    esac
}

# Function to test endpoint and capture response
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local auth_header=$4
    local description=$5

    echo ""
    print_status "INFO" "Testing: $description"
    echo "Method: $method"
    echo "URL: $url"

    if [ -n "$data" ]; then
        echo "Data: $data"
    fi

    # Build curl command
    local curl_cmd="curl -s -X $method"

    if [ -n "$auth_header" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $auth_header'"
    fi

    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi

    curl_cmd="$curl_cmd '$url'"

    echo "Command: $curl_cmd"
    echo ""

    # Execute curl command and capture response
    response=$(eval "$curl_cmd")
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X $method ${auth_header:+-H "Authorization: Bearer $auth_header"} ${data:+-H "Content-Type: application/json" -d "$data"} "$url")

    echo "HTTP Status Code: $http_code"
    echo "Response:"
    echo "$response"
    echo "----------------------------------------"

    # Store HTTP code in global variable and also return it
    TEST_HTTP_CODE=$http_code
    # Return a simple value (0 for success, 1 for error)
    [ $http_code -eq 200 ] || [ $http_code -eq 201 ] || [ $http_code -eq 401 ] || [ $http_code -eq 403 ]
}

echo "=========================================="
echo "    SECURE API TESTING SCRIPT"
echo "=========================================="
echo ""

# Test 1: Check if server is running
echo "TEST 1: Server Availability Check"
test_endpoint "GET" "$BASE_URL/auth/login" "" "" "Check if server is running"
if [ $TEST_HTTP_CODE -ne 405 ]; then
    print_status "SUCCESS" "Server is running"
else
    print_status "ERROR" "Server is not running or not accessible"
    exit 1
fi

echo ""
echo "=========================================="
echo "TEST 2: AUTHENTICATION TESTS"
echo "=========================================="

# Test 2.1: Login with valid credentials
echo "TEST 2.1: Valid Login"
login_data='{"username":"john_doe","password":"password123"}'
test_endpoint "POST" "$BASE_URL/auth/login" "$login_data" "" "Login with valid credentials"

if [ $TEST_HTTP_CODE -eq 200 ]; then
    # Extract token from response (assuming JSON response format)
    TOKEN=$(echo "$response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        print_status "SUCCESS" "Login successful, token obtained"
    else
        print_status "ERROR" "Login successful but failed to extract token"
    fi
else
    print_status "ERROR" "Login failed"
fi

# Test 2.2: Login with invalid credentials
echo ""
echo "TEST 2.2: Invalid Login"
invalid_login_data='{"username":"john_doe","password":"wrongpassword"}'
test_endpoint "POST" "$BASE_URL/auth/login" "$invalid_login_data" "" "Login with invalid credentials"

if [ $TEST_HTTP_CODE -eq 401 ]; then
    print_status "SUCCESS" "Invalid login correctly rejected with 401"
else
    print_status "ERROR" "Invalid login should return 401 (got $TEST_HTTP_CODE)"
fi

# Test 2.3: User registration
echo ""
echo "TEST 2.3: User Registration"
timestamp=$(date +%s)
random_suffix=$((RANDOM % 1000))
register_data='{"username":"testuser'$timestamp'_'$random_suffix'","password":"testpass123","name":"Test User"}'
test_endpoint "POST" "$BASE_URL/auth/register" "$register_data" "" "Register new user"

if [ $TEST_HTTP_CODE -eq 200 ] || [ $TEST_HTTP_CODE -eq 400 ]; then
    print_status "SUCCESS" "User registration completed (status: $TEST_HTTP_CODE)"
else
    print_status "ERROR" "User registration failed (got $TEST_HTTP_CODE)"
fi

echo ""
echo "=========================================="
echo "TEST 3: PROTECTED ENDPOINTS WITHOUT AUTH"
echo "=========================================="

# Test 3.1: Access protected endpoint without token
echo "TEST 3.1: Access /api/data without authentication"
test_endpoint "GET" "$BASE_URL/api/data" "" "" "Access protected endpoint without token"

if [ $TEST_HTTP_CODE -eq 401 ] || [ $TEST_HTTP_CODE -eq 403 ]; then
    print_status "SUCCESS" "Access correctly denied without authentication"
else
    print_status "ERROR" "Access should be denied without authentication"
fi

# Test 3.2: Access /api/posts without token
echo ""
echo "TEST 3.2: Access /api/posts without authentication"
test_endpoint "GET" "$BASE_URL/api/posts" "" "" "Access posts endpoint without token"

if [ $TEST_HTTP_CODE -eq 401 ] || [ $TEST_HTTP_CODE -eq 403 ]; then
    print_status "SUCCESS" "Access correctly denied without authentication"
else
    print_status "ERROR" "Access should be denied without authentication"
fi

# Test 3.3: Create post without token
echo ""
echo "TEST 3.3: Create post without authentication"
post_data='{"title":"Test Post","content":"This is a test post content"}'
test_endpoint "POST" "$BASE_URL/api/posts" "$post_data" "" "Create post without token"

if [ $TEST_HTTP_CODE -eq 401 ] || [ $TEST_HTTP_CODE -eq 403 ]; then
    print_status "SUCCESS" "Access correctly denied without authentication"
else
    print_status "ERROR" "Access should be denied without authentication"
fi

echo ""
echo "=========================================="
echo "TEST 4: PROTECTED ENDPOINTS WITH AUTH"
echo "=========================================="

if [ -n "$TOKEN" ]; then
    # Test 4.1: Access /api/data with valid token
    echo "TEST 4.1: Access /api/data with valid token"
    test_endpoint "GET" "$BASE_URL/api/data" "" "$TOKEN" "Access data endpoint with valid token"

    if [ $TEST_HTTP_CODE -eq 200 ]; then
        print_status "SUCCESS" "Access granted with valid token"
    else
        print_status "ERROR" "Access should be granted with valid token"
    fi

    # Test 4.2: Access /api/posts with valid token
    echo ""
    echo "TEST 4.2: Access /api/posts with valid token"
    test_endpoint "GET" "$BASE_URL/api/posts" "" "$TOKEN" "Access posts endpoint with valid token"

    if [ $TEST_HTTP_CODE -eq 200 ]; then
        print_status "SUCCESS" "Access granted with valid token"
    else
        print_status "ERROR" "Access should be granted with valid token"
    fi

    # Test 4.3: Create post with valid token
    echo ""
    echo "TEST 4.3: Create post with valid token"
    post_data='{"title":"Test Post from API","content":"This post was created via API testing script"}'
    test_endpoint "POST" "$BASE_URL/api/posts" "$post_data" "$TOKEN" "Create post with valid token"

    if [ $TEST_HTTP_CODE -eq 200 ]; then
        print_status "SUCCESS" "Post creation successful with valid token"
    else
        print_status "ERROR" "Post creation should succeed with valid token"
    fi
else
    print_status "WARNING" "Skipping authenticated tests - no valid token available"
fi

echo ""
echo "=========================================="
echo "TEST 5: SECURITY TESTS"
echo "=========================================="

# Test 5.1: XSS Protection Test
if [ -n "$TOKEN" ]; then
    echo "TEST 5.1: XSS Protection Test"
    xss_data='{"title":"Test <script>alert(\"XSS\")</script>","content":"Content with <b>HTML</b> tags"}'
    test_endpoint "POST" "$BASE_URL/api/posts" "$xss_data" "$TOKEN" "Test XSS protection in post creation"

    if [ $TEST_HTTP_CODE -eq 200 ]; then
        # Check if HTML was escaped in response
        if echo "$response" | grep -q '\\u003Cscript\\u003E' && echo "$response" | grep -q '\\u003Cb\\u003E'; then
            print_status "SUCCESS" "XSS protection working - HTML properly escaped with Unicode"
        else
            print_status "WARNING" "XSS protection may not be working properly"
        fi
    else
        print_status "ERROR" "XSS test failed due to request error"
    fi
fi

# Test 5.2: Test with different user
echo ""
echo "TEST 5.2: Login with different user"
admin_login_data='{"username":"admin","password":"admin123"}'
test_endpoint "POST" "$BASE_URL/auth/login" "$admin_login_data" "" "Login as admin user"

if [ $TEST_HTTP_CODE -eq 200 ]; then
    ADMIN_TOKEN=$(echo "$response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    if [ -n "$ADMIN_TOKEN" ]; then
        print_status "SUCCESS" "Admin login successful"

        # Test accessing data with admin token
        echo ""
        echo "TEST 5.3: Access data with admin token"
        test_endpoint "GET" "$BASE_URL/api/data" "" "$ADMIN_TOKEN" "Access data as admin"

        if [ $TEST_HTTP_CODE -eq 200 ]; then
            print_status "SUCCESS" "Admin access successful"
        fi
    fi
fi

