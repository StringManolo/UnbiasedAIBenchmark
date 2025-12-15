##  Test 3. Complete the missing bash function from 1047 lines bash code. (no thinking)

- A 1047 lines of bash file is uploaded for a freedns bash client missing the --help function.

- Prompt: Implement the showUsage() function using colors and following the code patterns and style of the rest of the code so i can copy and paste it directly on my file.

- Expected result:  
The full bash function using the not included library colors, all available "apis" shown in the output of the code. Minimum the working functions od the client should be shown to the user with arguments.  

This an example of a expected and very complete implementation of such function:
```bash
showUsage() {
cat << SHOWUSAGE
$(cli color bold red USAGE)
./freedns.sh [$(cli color bold green "command")] [$(cli color bold cyan subcommand)] [options]

$(cli color bold red COMMANDS)
  $(cli color bold green account)
    $(cli color bold cyan create) --email --password --firstname --lastname --username
    $(cli color bold cyan login) --email --password
    $(cli color bold cyan status)
    $(cli color bold cyan logout)
    $(cli color bold cyan edit)
    $(cli color bold cyan delete)

  $(cli color bold green domain)
    $(cli color bold cyan create)
    $(cli color bold cyan list)
    $(cli color bold cyan edit)
    $(cli color bold cyan delete)

  $(cli color bold green subdomain)
    $(cli color bold cyan available)
    $(cli color bold cyan create) --domain --subdomain ( --record --address )
    $(cli color bold cyan list)
    $(cli color bold cyan edit)
    $(cli color bold cyan delete)

$(cli color bold red OPTIONS)
-a, --address
-e, --email
-p, --password
    --domain
-s, --subdomain
-r, --record A AAAA CNAME CAA NS MX TXT SPF LOC HINFO RP SVR SSHFP
    --record-value
    --destination
    --firstname
    --lastname
    --username

-v, --verbose
-d, --debug

--version

$(cli color bold red EXAMPLES)
./freedns.sh $(cli color bold green account) $(cli color bold cyan create) --firstname Manolo --lastname String --username stringmanolo --email stringmanolo@gmail.com --password myPassword123
./freedns.sh $(cli color bold green account) $(cli color bold cyan login) -e stringmanolo@gmail.com -p myPassword123
./freedns.sh $(cli color bold green subdomain) $(cli color bold cyan available)
./freedns.sh $(cli color bold green subdomain) $(cli color bold cyan create) --domain mooo.com --subdomain stringmanolo

SHOWUSAGE

builtin exit
}
```

File sent to models is available here [clientFreeDNS.sh]()

#### ChatGPT-5.2 Instant
- Result:
```bash
showUsage() {
  echo ""
  echo "$(cli color bold cyan "FreeDNS CLI")"
  echo "$(cli color white "==================================================================")"
  echo ""
  echo "  $(cli color bold green "Usage:")"
  echo "    ./freedns.sh $(cli color bold cyan "<command>") $(cli color bold cyan "<subcommand>") [options]"
  echo ""
  echo "  $(cli color bold green "Global options:")"
  echo "    $(cli color bold yellow "-h, --help")        Show this help"
  echo "    $(cli color bold yellow "-v, --verbose")     Verbose output"
  echo "    $(cli color bold yellow "-d, --debug")       Debug mode"
  echo "    $(cli color bold yellow "--version")         Show version"
  echo ""
  echo "  $(cli color bold green "Commands:")"
  echo ""
  echo "    $(cli color bold cyan "account")"
  echo "      $(cli color yellow "create")    Create a new account"
  echo "      $(cli color yellow "login")     Login into an existing account"
  echo "      $(cli color yellow "status")    Show account status"
  echo "      $(cli color yellow "logout")    Logout and remove session"
  echo "      $(cli color yellow "edit")      Edit account (not implemented)"
  echo "      $(cli color yellow "delete")    Delete account (not implemented)"
  echo ""
  echo "    $(cli color bold cyan "domain")"
  echo "      $(cli color yellow "create")    Create domain (not implemented)"
  echo "      $(cli color yellow "list")      List domains (not implemented)"
  echo "      $(cli color yellow "edit")      Edit domain (not implemented)"
  echo "      $(cli color yellow "delete")    Delete domain (not implemented)"
  echo ""
  echo "    $(cli color bold cyan "subdomain")"
  echo "      $(cli color yellow "available") List available public domains"
  echo "      $(cli color yellow "create")    Create a subdomain"
  echo "      $(cli color yellow "list")      List your subdomains"
  echo "      $(cli color yellow "edit")      Edit subdomain (not implemented)"
  echo "      $(cli color yellow "delete")    Delete subdomain (not implemented)"
  echo ""
  echo "  $(cli color bold green "Examples:")"
  echo "    ./freedns.sh account create -e mail@example.com -p secret"
  echo "    ./freedns.sh account login -e mail@example.com -p secret"
  echo "    ./freedns.sh subdomain available"
  echo "    ./freedns.sh subdomain create --domain example.com -s test -a 1.2.3.4"
  echo ""
  echo "$(cli color white "==================================================================")"
  echo ""
  builtin exit 0
}

```
  

- Evaluation: 77.5 / 100
  - Task:  30 
  - Time: 80 (18.47 Seconds)
  - Output noise: 100
  - Output usefull non requested info: 100
 

#### Gemini 3.0 flash
- Result:
```bash
showUsage() {
  echo ""
  echo "$(cli color bold green $version)"
  echo ""
  echo "Usage: $(cli color bold white ./freedns.sh) $(cli color cyan <command>) $(cli color yellow <subcommand>) [options]"
  echo ""
  
  echo "$(cli color bold white "Commands:")"
  
  echo "  $(cli color cyan account)          Manage your FreeDNS account (login, create, etc.)"
  echo "    $(cli color yellow login)         Log into your account."
  echo "    $(cli color yellow create)        Create a new account."
  echo "    $(cli color yellow logout)        Remove session cookies."
  echo "    $(cli color yellow status)        [WIP] Show account status."
  
  echo "  $(cli color cyan subdomain)        Manage your subdomains (list, create, available, etc.)"
  echo "    $(cli color yellow available)     Show all domains available for creating a new subdomain."
  echo "    $(cli color yellow create)        Create a new subdomain. Requires $(cli color bold cyan --domain --subdomain --address --record)."
  echo "    $(cli color yellow list)          List all your subdomains."
  echo "    $(cli color yellow edit)          [WIP] Edit an existing subdomain."
  echo "    $(cli color yellow delete)        [WIP] Delete an existing subdomain."
  
  echo "  $(cli color cyan domain)           [WIP] Manage your own custom domains."
  echo "    $(cli color yellow list)          [WIP] List your custom domains."
  echo "    $(cli color yellow create)        [WIP] Add a new custom domain."
  
  echo "$(cli color bold white "Global Options:")"
  echo "  $(cli color green -h, --help)         Show this help message."
  echo "  $(cli color green -v, --verbose)      Enable verbose output."
  echo "  $(cli color green -d, --debug)        Enable debug output."
  echo "  $(cli color green --version)          Show the current version."
  echo ""
  
  echo "$(cli color bold white "Command Options (subdomain create):")"
  echo "  $(cli color green --domain) <domain>    The domain you want to use (e.g., $(cli color yellow 'chickenkiller.com')). Required."
  echo "  $(cli color green -s, --subdomain) <subd> The subdomain name (e.g., $(cli color yellow 'my-site')). Required."
  echo "  $(cli color green -a, --address) <ip>     The IP address for A/AAAA records (default: $(cli color yellow '127.0.0.1')). Optional."
  echo "  $(cli color green -r, --record) <type>    The DNS record type (e.g., $(cli color yellow 'A, CNAME, MX')). Optional (default: $(cli color yellow 'A')). "
  echo ""
  
  echo "$(cli color bold white "Command Options (account login/create):")"
  echo "  $(cli color green -e, --email) <email>    Your account email. Required."
  echo "  $(cli color green -p, --password) <pass>  Your account password. Required."
  echo "  $(cli color green --firstname) <name>     Required for $(cli color cyan account) $(cli color yellow create)."
  echo "  $(cli color green --lastname) <name>      Required for $(cli color cyan account) $(cli color yellow create)."
  echo "  $(cli color green --username) <name>      Required for $(cli color cyan account) $(cli color yellow create)."
  echo ""

  echo "$(cli color bold white "Examples:")"
  echo "  $(cli color bold white ./freedns.sh) $(cli color cyan account) $(cli color yellow create) -e $(cli color yellow 'user@email.com') -p $(cli color yellow 'mypass') --firstname $(cli color yellow 'John') --lastname $(cli color yellow 'Doe') --username $(cli color yellow 'myuser')"
  echo "  $(cli color bold white ./freedns.sh) $(cli color cyan account) $(cli color yellow login) -e $(cli color yellow 'user@email.com') -p $(cli color yellow 'mypass')"
  echo "  $(cli color bold white ./freedns.sh) $(cli color cyan subdomain) $(cli color yellow create) --domain $(cli color yellow 'chickenkiller.com') -s $(cli color yellow 'test') -a $(cli color yellow '1.2.3.4')"
  echo "  $(cli color bold white ./freedns.sh) $(cli color cyan subdomain) $(cli color yellow list)"
  echo ""
}
```

- Evaluation: 67.75 / 100
  - Task:  10
  - Time: 91  (8.88 Seconds)
  - Output noise: 70
  - Output usefull non requested info: 100
 


#### DeepSeek 3.2 
- Result:
```bash
showUsage() {
  echo ""
  echo "$(cli color bold cyan "FreeDNS CLI - Command Line Interface for FreeDNS.Afraid.org")"
  echo "$(cli color green "Version: 0.0.1")"
  echo ""
  echo "$(cli color bold white "USAGE:")"
  echo "  ./freedns.sh [COMMAND] [SUBCOMMAND] [OPTIONS]"
  echo ""
  echo "$(cli color bold white "GLOBAL OPTIONS:")"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -d, --debug                Enable debug mode"
  echo "      --version              Show version information"
  echo ""
  echo "$(cli color bold white "ACCOUNT COMMANDS:")"
  echo "  account create             Create a new account"
  echo "    Required:"
  echo "      --firstname <name>     First name"
  echo "      --lastname <name>      Last name"
  echo "      --username <name>      Username (3-16 alphanumeric chars)"
  echo "      -e, --email <email>    Email address"
  echo "      -p, --password <pass>  Password (4-16 characters)"
  echo ""
  echo "  account login              Log into account"
  echo "    Required:"
  echo "      -e, --email <email>    Email address"
  echo "      -p, --password <pass>  Password"
  echo ""
  echo "  account logout             Log out (clear session cookies)"
  echo "  account status             Show account status"
  echo "  account edit               Edit account information"
  echo "  account delete             Delete account"
  echo ""
  echo "$(cli color bold white "DOMAIN COMMANDS:")"
  echo "  domain create              Create a new domain"
  echo "  domain list                List your domains"
  echo "  domain edit                Edit domain"
  echo "  domain delete              Delete domain"
  echo ""
  echo "$(cli color bold white "SUBDOMAIN COMMANDS:")"
  echo "  subdomain available        Show available domains for subdomains"
  echo ""
  echo "  subdomain create           Create a new subdomain"
  echo "    Required:"
  echo "      --domain <name>        Domain name (e.g., chickenkiller.com)"
  echo "      -s, --subdomain <name> Subdomain prefix"
  echo "    Optional:"
  echo "      -a, --address <ip>     IP address (default: 127.0.0.1)"
  echo "      -r, --record <type>    Record type (default: A)"
  echo ""
  echo "  subdomain list             List your subdomains"
  echo "  subdomain edit             Edit subdomain"
  echo "  subdomain delete           Delete subdomain"
  echo ""
  echo "$(cli color bold white "EXAMPLES:")"
  echo "  Create account:"
  echo "    ./freedns.sh account create --firstname John --lastname Doe \\"
  echo "      --username johndoe -e john@example.com -p secret123"
  echo ""
  echo "  Login:"
  echo "    ./freedns.sh account login -e john@example.com -p secret123"
  echo ""
  echo "  Create subdomain:"
  echo "    ./freedns.sh subdomain create --domain chickenkiller.com \\"
  echo "      -s mysub -a 192.168.1.100"
  echo ""
  echo "  List subdomains:"
  echo "    ./freedns.sh subdomain list"
  echo ""
  echo "  Show available domains:"
  echo "    ./freedns.sh subdomain available"
  echo ""
  echo "$(cli color bold white "NOTES:"))"
  echo "  • Session cookies are stored in $(cli color cyan "./cookies.txt")"
  echo "  • You need to login before using most commands"
  echo "  • CAPTCHA images are displayed in terminal using $(cli color cyan "chafa")"
  echo "  • Configure domains in $(cli color cyan "./subdomainList.config")"
  echo ""
  echo "$(cli color green "GitHub: https://github.com/stringmanolo")"
  echo ""
  builtin exit 0
}
```

- Evaluation: 78.75 / 100
  - Task:  70 
  - Time: 60 (44.58 Seconds)
  - Output noise: 85
  - Output usefull non requested info: 100
 


#### Sonnet 4.5
- Result:
```bash
showUsage() {
  echo ""
  echo "$(cli color bold bright_cyan "FreeDNS CLI Client") - Manage your FreeDNS account and domains"
  echo "$(cli color bold white "==================================================================")"
  echo ""
  echo "$(cli color bold green "USAGE:")"
  echo "  ./freedns.sh $(cli color cyan "[COMMAND]") $(cli color yellow "[SUBCOMMAND]") $(cli color magenta "[OPTIONS]")"
  echo ""
  echo "$(cli color bold green "COMMANDS:")"
  echo ""
  echo "  $(cli color bold cyan "account")     Manage your FreeDNS account"
  echo "    $(cli color yellow "create")      Create a new account"
  echo "    $(cli color yellow "login")       Login to your account"
  echo "    $(cli color yellow "logout")      Logout from your account"
  echo "    $(cli color yellow "status")      Show account status $(cli color red "(not implemented)")"
  echo "    $(cli color yellow "edit")        Edit account details $(cli color red "(not implemented)")"
  echo "    $(cli color yellow "delete")      Delete your account $(cli color red "(not implemented)")"
  echo ""
  echo "  $(cli color bold cyan "domain")      Manage your domains"
  echo "    $(cli color yellow "create")      Create a new domain $(cli color red "(not implemented)")"
  echo "    $(cli color yellow "list")        List all your domains $(cli color red "(not implemented)")"
  echo "    $(cli color yellow "edit")        Edit domain settings $(cli color red "(not implemented)")"
  echo "    $(cli color yellow "delete")      Delete a domain $(cli color red "(not implemented)")"
  echo ""
  echo "  $(cli color bold cyan "subdomain")   Manage your subdomains"
  echo "    $(cli color yellow "available")   Show available domains for subdomains"
  echo "    $(cli color yellow "create")      Create a new subdomain"
  echo "    $(cli color yellow "list")        List all your subdomains"
  echo "    $(cli color yellow "edit")        Edit subdomain settings $(cli color red "(not implemented)")"
  echo "    $(cli color yellow "delete")      Delete a subdomain $(cli color red "(not implemented)")"
  echo ""
  echo "$(cli color bold green "OPTIONS:")"
  echo "  $(cli color magenta "-h, --help")              Show this help message"
  echo "  $(cli color magenta "-v, --verbose")          Enable verbose output"
  echo "  $(cli color magenta "-d, --debug")            Enable debug mode"
  echo "  $(cli color magenta "--version")              Show version information"
  echo ""
  echo "  $(cli color magenta "-e, --email")            Email address"
  echo "  $(cli color magenta "-p, --password")         Password"
  echo "  $(cli color magenta "-s, --subdomain")        Subdomain name"
  echo "  $(cli color magenta "-a, --address")          IP address or target"
  echo "  $(cli color magenta "-r, --record")           Record type (A, AAAA, CNAME, MX, TXT, URL)"
  echo "  $(cli color magenta "--domain")               Domain name"
  echo "  $(cli color magenta "--firstname")            First name (for account creation)"
  echo "  $(cli color magenta "--lastname")             Last name (for account creation)"
  echo "  $(cli color magenta "--username")             Username (for account creation)"
  echo ""
  echo "$(cli color bold green "EXAMPLES:")"
  echo ""
  echo "  $(cli color white "# Create a new account")"
  echo "  ./freedns.sh $(cli color cyan "account") $(cli color yellow "create") $(cli color magenta "--firstname") John $(cli color magenta "--lastname") Doe $(cli color magenta "--username") johndoe $(cli color magenta "-e") john@example.com $(cli color magenta "-p") mypassword"
  echo ""
  echo "  $(cli color white "# Login to your account")"
  echo "  ./freedns.sh $(cli color cyan "account") $(cli color yellow "login") $(cli color magenta "-e") john@example.com $(cli color magenta "-p") mypassword"
  echo ""
  echo "  $(cli color white "# Show available domains")"
  echo "  ./freedns.sh $(cli color cyan "subdomain") $(cli color yellow "available")"
  echo ""
  echo "  $(cli color white "# Create a subdomain")"
  echo "  ./freedns.sh $(cli color cyan "subdomain") $(cli color yellow "create") $(cli color magenta "-s") myapp $(cli color magenta "--domain") chickenkiller.com $(cli color magenta "-a") 192.168.1.100 $(cli color magenta "-r") A"
  echo ""
  echo "  $(cli color white "# List your subdomains")"
  echo "  ./freedns.sh $(cli color cyan "subdomain") $(cli color yellow "list")"
  echo ""
  echo "  $(cli color white "# Logout")"
  echo "  ./freedns.sh $(cli color cyan "account") $(cli color yellow "logout")"
  echo ""
  echo "$(cli color bold white "==================================================================")"
  echo "$(cli color bold green "VERSION:") $version"
  echo "$(cli color bold green "PROJECT:") $(cli color cyan "https://github.com/stringmanolo/clientFreeDNS")"
  echo ""
  builtin exit 0
}
```

- Evaluation: 92 / 100
  - Task: 98 
  - Time: 70 (27.92 Seconds)
  - Output noise: 100
  - Output usefull non requested info: 100
 


#### Kimi K2
- Result:
```bash
showUsage() {
  echo
  echo "$(cli color bold bright_cyan FreeDNS Command-Line Interface)"
  echo "$(cli color bold white  https://github.com/stringmanolo)"
  echo
  echo "$(cli color bold green USAGE:)"
  echo "  $(cli color cyan ./freedns.sh) $(cli color yellow '<command>') $(cli color magenta '<subcommand>') [$(cli color white options)]"
  echo
  echo "$(cli color bold green COMMANDS:)"
  echo "  $(cli color yellow account)    Manage your FreeDNS account"
  echo "  $(cli color yellow domain)     Manage domains (not implemented)"
  echo "  $(cli color yellow subdomain)  Manage subdomains"
  echo "  $(cli color yellow help)       Show this help message"
  echo
  echo "$(cli color bold green ACCOUNT SUBCOMMANDS:)"
  echo "  $(cli color magenta create)   Create a new account"
  echo "    $(cli color white --firstname) $(cli color cyan '<name>')  First name"
  echo "    $(cli color white --lastname)  $(cli color cyan '<name>')  Last name"
  echo "    $(cli color white --username)  $(cli color cyan '<user>')  Username (3-16 alphanumeric chars)"
  echo "    $(cli color white --email)     $(cli color cyan '<addr>')  Email address"
  echo "    $(cli color white --password)  $(cli color cyan '<pass>')  Password (4-16 chars)"
  echo
  echo "  $(cli color magenta login)    Log into an existing account"
  echo "    $(cli color white -e) $(cli color cyan '<email>')    Account email"
  echo "    $(cli color white -p) $(cli color cyan '<pass>')    Account password"
  echo
  echo "  $(cli color magenta logout)   Log out current session"
  echo "  $(cli color magenta status)   Show account status (not implemented)"
  echo "  $(cli color magenta edit)     Edit account details (not implemented)"
  echo "  $(cli color magenta delete)   Delete account (not implemented)"
  echo
  echo "$(cli color bold green SUBDOMAIN SUBCOMMANDS:)"
  echo "  $(cli color magenta available)  List available parent domains"
  echo "  $(cli color magenta create)     Create a new subdomain"
  echo "    $(cli color white -s) $(cli color cyan '<name>')   Subdomain name"
  echo "    $(cli color white -d) $(cli color cyan '<domain>') Parent domain"
  echo "    $(cli color white -a) $(cli color cyan '<IP>')     Target IP address (default: 127.0.0.1)"
  echo "    $(cli color white -r) $(cli color cyan '<type>')   Record type: A, AAAA, CNAME, MX, TXT, URL (default: A)"
  echo
  echo "  $(cli color magenta list)       List your active subdomains"
  echo "  $(cli color magenta edit)       Edit subdomain (not implemented)"
  echo "  $(cli color magenta delete)     Delete subdomain (not implemented)"
  echo
  echo "$(cli color bold green GLOBAL OPTIONS:)"
  echo "  $(cli color white -h, --help)      Show help for any command/subcommand"
  echo "  $(cli color white -v, --verbose)   Enable verbose output"
  echo "  $(cli color white -d, --debug)     Enable debug output"
  echo "  $(cli color white --version)        Show version"
  echo
  echo "$(cli color bold green EXAMPLES:)"
  echo "  $(cli color dim ./freedns.sh account create --firstname Ada --lastname Lovelace --username ada1842 --email ada@example.com --password myS3cret)"
  echo "  $(cli color dim ./freedns.sh account login -e ada@example.com -p myS3cret)"
  echo "  $(cli color dim ./freedns.sh subdomain available)"
  echo "  $(cli color dim ./freedns.sh subdomain create -s myapp -d chickenkiller.com -a 192.0.2.42)"
  echo "  $(cli color dim ./freedns.sh subdomain list)"
  echo
  exit 0
}
```

- Evaluation: 80.75 / 100
  - Task: 93 
  - Time: 30 (67.48 Seconds)
  - Output noise: 100 
  - Output usefull non requested info: 100
 
