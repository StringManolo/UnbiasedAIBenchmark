#!/usr/bin/env bash

source ./parseCLI
parse_cli "$@"

# globals
version="FreeDNS $(cli color bold green 0.0.1) by https://github.com/stringmanolo"
verbose=false
debug=false

# This is for install dependencies like CHAFA to view captchas in terminal, etc.
install_pkg_on_unknown_distro() {
  if [ -z "$1" ]; then
    return 1
  fi

  PKG_NAME="$1"
  declare -a MANAGERS=(
    "apt install -y"
    "yum install -y"
    "dnf install -y"
    "pacman -S --noconfirm"
    "zypper install -y"
    "apk add"
    "pkg install -y"
    "xbps-install -y"
  )

  for MANAGER_BASE in "${MANAGERS[@]}"; do
    for PREFIX in "sudo" ""; do
      INSTALL_CMD="$PREFIX $MANAGER_BASE $PKG_NAME"
      $INSTALL_CMD >/dev/null 2>&1

      if [ $? -eq 0 ]; then
        return 0
      fi
    done
  done

  return 1
}

# Ouput utils
exit() {
  local msg="$1"
  echo -e "$msg"
  builtin exit 0
}

info() {
  echo "$(cli color cyan [INFO]) $1"
}

success() {
  echo "$(cli color green [SUCCESS]) $1"
}

error() {
  echo "$(cli color bold red [ERROR]) $1"
  builtin exit
}

warning() {
  echo "$(cli color yellow [WARNING]) $1"
}

# Printing when using ./freedns.sh help ./freedns.sh ./freedns.sh --help, etc.
showUsage() {
}

# The HTTP Request to subdomain creation needs an ID for the domain. 
getSubdomainID() {
  local CONFIG_FILE="./subdomainList.config"
  local domain="$1"
  
  if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Error: Config file $(cli color bold yellow "$CONFIG_FILE") not found"
  fi
  
  local result=$(grep -i "^$domain " "$CONFIG_FILE" | head -1)

  if [[ -z "$result" ]]; then
    error "subdomain $(cli color bold yellow "$domain") not found in $(cli color bold yellow "$CONFIG_FILE")"
  fi
  
  echo "$result" | awk '{print $2}'
}

# THIS DOES NOT WORK, NEED SOME TWEAKS TO MAKE IT WORK. BUT I DON'T NEED AUTOMATION ANYWAYS. NOT WORTH THE TIME INVESTMENT.
# KEEPING IT HERE IN CASE I WAMT TO PLAY AROUND WITH IT.
# Try to resolve captcha without user interaction using Gemini 2.5-flash model.
resolveCaptcha() {
  IMAGE_PATH="$1"

  if [ -z "$IMAGE_PATH" ]; then
    error "resolveCaptcha could not find the image"
    return 1
  fi

  if [ -z "$GEMINI_API_KEY" ]; then
    warning "Define your key: export GEMINI_API_KEY='YourKeyHere'"
    error "GEMINI_API_KEY environment variable is not defined."
  fi

  if [ ! -f "$IMAGE_PATH" ]; then
    error "Image file not found at: $IMAGE_PATH"
  fi

  B64_IMAGE=$(cat "$IMAGE_PATH" | base64 | tr -d '\n')
  MIME_TYPE="image/png"

  INSTRUCTION="You are a dedicated and highly accurate OCR specialist. Your sole task is to read the characters displayed in the provided image, which is a CAPTCHA. Provide only the extracted text and nothing else, without any explanation, markdown, or commentary."
  OCR_PROMPT="Extract the text characters from this image."
  FINAL_PROMPT="$INSTRUCTION $OCR_PROMPT"

  RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" \
    -H 'Content-Type: application/json' \
    -H "X-goog-api-key: $GEMINI_API_KEY" \  # Get it here https://aistudio.google.com/apikey
    -X POST \
    -d "{
      \"contents\": [
        {
          \"parts\": [
            {
              \"inlineData\": {
                \"data\": \"$B64_IMAGE\",
                \"mimeType\": \"$MIME_TYPE\"
              }
            },
            {
              \"text\": \"$FINAL_PROMPT\"
            }
          ]
        }
      ]
    }" )

  CAPTCHA_TEXT=$(echo "$RESPONSE" | jq -r '.candidates[]?.content?.parts[]?.text')

  if [ -z "$CAPTCHA_TEXT" ]; then
    error "Failed to resolve CAPTCHA or 'jq' extraction error."
  fi

  echo "$CAPTCHA_TEXT"
}

# Create a new account
accountCreate() {
  local firstname=""
  local lastname=""
  local username=""
  local password=""
  local email=""
  
  cli s e && email=${__CLI_S[e]}
  cli c email && email=${__CLI_C[email]}
  
  cli s p && password=${__CLI_S[p]}
  cli c password && password=${__CLI_C[password]}
  
  cli c firstname && firstname=${__CLI_C[firstname]}
  cli c lastname && lastname=${__CLI_C[lastname]}
  cli c username && username=${__CLI_C[username]}
  
  [[ -z "$firstname" ]] && error "First name is required. Use --firstname"
  [[ -z "$lastname" ]] && error "Last name is required. Use --lastname"
  [[ -z "$username" ]] && error "Username is required. Use --username"
  [[ -z "$password" ]] && error "Password is required. Use -p or --password"
  [[ -z "$email" ]] && error "Email is required. Use -e or --email"
  
  [[ ! $username =~ ^[a-zA-Z0-9]{3,16}$ ]] && 
    error "Username must be 3-16 characters and alphanumeric only"
  
  [[ ! $password =~ ^.{4,16}$ ]] &&
    error "Password must be 4-16 characters"
  
  [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,15}$ ]] &&
    error "Email $(cli color bold red "$email") is not valid"
  
  info "Getting captcha for signup..."
 
  # Get cookies to simulate already being at the signup page (probably not needed)
  curl 'https://freedns.afraid.org/signup/' \
    -c "./account_create_cookies.txt" \
    -o "./account_create_page.html" \
    -L --silent >/dev/null 2>&1
  
  # Get CAPTCHA image
  curl 'https://freedns.afraid.org/securimage/securimage_show.php' \
    -b "./account_create_cookies.txt" \
    -c "./account_create_cookies.txt" \
    -o "./account_create_captcha.png" \
    -L --silent >/dev/null 2>&1
  
  # Install chafa to print captcha directly into terminal
  if ! install_pkg_on_unknown_distro chafa; then
    warning "Unable to install $(cli color bold cyan chafa) to display captcha"
  fi
  
  if command -v chafa &> /dev/null; then
    # 80x30 This same ratio as original image but smaller to fit into screen
    # If you edit the width / height try to keep the same aspect ratio (quality)
    # A.K.A multiply both numbers for the same number: 80x30 * 1.5 === 120x45
    chafa --size 80x30 './account_create_captcha.png'
  else
    info "Captcha saved to: $(cli color bold cyan ./account_create_captcha.png)"
    info "Open the image to see the captcha"
  fi
  
  # Get CAPTCHA from user
  local captchaCode=""
  while [[ -z "$captchaCode" ]]; do
    read -r -p "$(cli color cyan "Enter captcha text"): " captchaCode
  done
  
  info "Creating account $(cli color bold cyan "$username")..."
  
  # Submit signup request
  curl -X POST 'https://freedns.afraid.org/signup/?step=2' \
    -b "./account_create_cookies.txt" \
    -c "./account_create_cookies.txt" \
    -d "plan=starter" \
    -d "firstname=$firstname" \
    -d "lastname=$lastname" \
    -d "username=$username" \
    -d "password=$password" \
    -d "password2=$password" \
    -d "email=$email" \
    -d "captcha_code=$captchaCode" \
    -d "tos=1" \
    -d "action=signup" \
    -d "send=Send+activation+email" \
    -o "./account_create_response.html" \
    -L --silent >/dev/null 2>&1
  
  # Check for errors in response
  if grep -q "The security code was incorrect" "./account_create_response.html"; then
    rm -f "./account_create_cookies.txt" "./account_create_captcha.png" \
      "./account_create_page.html" "./account_create_response.html"
    error "Captcha $(cli color bold red "$captchaCode") was wrong. Try again"
  fi
  
  if grep -q "Username already exists" "./account_create_response.html" || 
     grep -q "Username in use" "./account_create_response.html"; then
    rm -f "./account_create_cookies.txt" "./account_create_captcha.png" \
      "./account_create_page.html" "./account_create_response.html"
    error "Username $(cli color bold red "$username") is already taken. Choose another"
  fi
  
  if grep -q "That e-mail is in use" "./account_create_response.html"; then
    rm -f "./account_create_cookies.txt" "./account_create_captcha.png" \
      "./account_create_page.html" "./account_create_response.html"
    error "Email $(cli color bold red "$email") is already registered"
  fi

  # If we got here, account creation was likely successful
  success "Account created"
  info "Activation email sent to: $(cli color bold cyan "$email")"
  warning "Check your spam folder if you don't see it in your inbox."
  echo ""
  
  # Ask for activation code
  local activationLink=""
  info "Open your email and find the activation link. Email takes around 30s to be available in your Spam folder"
  info "You can paste the activation link here or in your browser. Link should be something like $(cli color bold cyan "http://freedns.afraid.org/signup/activate.php?QWuZMkdyws2IlIWJSdowxMHBa")"
  echo ""
  
  while [[ -z "$activationLink" ]]; do
    read -r -p "$(cli color cyan "Enter URL"): " activationLink
  done
  
  info "Activating account with URL: $(cli color bold cyan "$activationLink")"
  
  # Activate account
  curl "$activationLink" \
    -b "./account_create_cookies.txt" \
    -c "./account_create_cookies.txt" \
    -L --silent >/dev/null 2>&1

  # Not saving response. Asuming accoint activation worked
  # -o "./account_activate_response.html" \

  # Cleanup
  rm -f "./account_create_cookies.txt" "./account_create_captcha.png" \
    "./account_create_page.html" "./account_create_response.html" \
    "./account_activate_response.html"

  echo ""
  exit "Account activated. Use next command to log in.

./freedns.sh $(cli color bold green account) $(cli color bold cyan login) -e $email -p $password 

If you can't log in, try the link $(cli color bold cyan "$activationLink") directly on any browser"
}

# Log into the account (A.K.A get the session cookies) 
accountLogin() {
  # Get email
  email="[MISSING]"
  cli s e && email=${__CLI_S[e]}
  cli c email && email=${__CLI_C[email]}
  [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,15}$ ]] &&
    error "Email $(cli color bold red "$email") is not valid"

  # Get password
  password=""
  cli s p && password=${__CLI_S[p]}
  cli c password && password=${__CLI_C[password]}
  [[ ! $password =~ ^.{4,16}$ ]] && 
    error "Password $(cli color bold red "$password") is not valid.
  4 to 16 characters required and your password is $(cli color bold red "${#password}") characters long"

  # Try to log into the account
  [[ -f './freednsresponse.html' ]] &&  rm './freednsresponse.html';
  curl -X POST 'https://freedns.afraid.org/zc.php?step=2' \
  -d "username=$email" \
  -d "password=$password" \
  -d "remember=1" \
  -d "action=auth" \
  -c "./cookies.txt" \
  -o './freednsresponse.html' \
  -L --silent
 
  # Find "Logged in as" text into the html response to confirm user is logged in.
  grep -q 'Logged in as ' './freednsresponse.html' ||  (rm './cookies.txt' && error "Unable to login. Make sure your credentials are correct.
  Email: $(cli color bold cyan "$email") 
  Password: $(cli color bold cyan "$password")

  If everything is right check the file $(cli color bold cyan "./freednsresponse.html")");


  # Here user logged in sucessfully
  [[ -f './freednsresponse.html' ]] &&  rm './freednsresponse.html';
  
  exit "$(cli color bold bright_cyan AUTHENTICATED.) $(cli color cyan You are now logged in)"

}

accountStatus() {
  warning "Not implemented"
}

accountLogout() {
  [[ -f './cookies.txt' ]] && rm -f './cookies.txt' 
  info "You are logged out"
  builtin exit
}

accountEdit() {
  warning "Not implemented"
}

accountDelete() {
  warning "Not implemented"
}

domainCreate() {
  warning "Not implemented"
}

domainList() {
  warning "Not implemented"
}

domainEdit() {
  warning "Not implemented"
}

domainDelete() {
  warning "Not implemented"
}

subdomainAvailable() {
  local config_file="subdomainList.config"
  local total=$(wc -l < "$config_file")

  if [[ ! -f "$config_file" ]]; then
    error "No available domains. Config file $(cli color bold yellow "$config_file") not found"
    return 1
  fi

  echo ""
  echo "Popular domains offering subdomains"
  echo "$(cli color bold white "  -----------------------------------------------------------------------")"
  echo ""

  local coloredDomain=0
  local input_data=""

  while IFS=' ' read -r domain _; do
    
    if [[ $coloredDomain -eq 0 ]]; then
      local colored_domain="$(cli color bold yellow "$domain")" 
    else
      local colored_domain="$(cli color bold cyan "$domain")"
    fi

    input_data+="$colored_domain\n" 
    coloredDomain=$(( 1 - coloredDomain ))
  done < "$config_file"

  echo -e "$input_data" | awk '
  {
    line = $0
    temp_line = line
    
    gsub(/\x1b\[[0-9;]*m/, "", temp_line)
    
    len = length(temp_line)
    
    columnas = 3
    ancho_columna = 26 
    
    padding = ancho_columna - len

    printf("  %s", line)
    
    for (i = 0; i < padding; i++) {
      printf(" ")
    }

    if (NR % columnas == 0) {
      printf("\n\n")
    }
  }
  END {
    if (NR % columnas != 0) {
      printf("\n")
    }
  }'

  echo ""
  echo "$(cli color bold white "  -----------------------------------------------------------------------")"
  echo ""
  info "Found $(cli color cyan "$total") domains available"
}

subdomainCreate() {
  # TODO Only info on -v or -d
  info 'Getting captcha ...'
  curl 'https://freedns.afraid.org/securimage/securimage_show.php' \
  -b "./cookies.txt" \
  -c "./cookies.txt" \
  -o "./freednsCaptchaResponse.png" \
  -L --silent

  if ! install_pkg_on_unknown_distro chafa; then
    error "Unable to find package manager to install $(cli color bold cyan "chafa"), please do manually."
fi 
  if ! install_pkg_on_unknown_distro jq; then
    error "Unable to find package manager to install $(cli color bold cyan "jq"), please do manually."
  fi

  chafa --size 80x30 './freednsCaptchaResponse.png'

  # info "Trying to solve captcha using AI"
  local captchaCode=""
  # captchaCode=$(resolveCaptcha './freednsCaptchaResponse.png')
  # info "Captcha resolved by AI: $(cli color bold cyan "$captchaCode")";

  read -r -p "Please, enter the captcha text and press enter: " captchaCode
  # TODO: Try OCR instead of AI to complete captcha.

  # echo "Captcha is: $captchaCode"

  local domainID=29;
  local domain="";
  local subdomain=""
  local address="127.0.0.1"
  local record="A"

  cli c domain && domain=${__CLI_C[domain]}
  domainID=$(getSubdomainID $domain)

  cli s s && subdomain=${__CLI_S[s]}
  cli c subdomain && subdomain=${__CLI_C[subdomain]}

  cli s a && address=${__CLI_S[a]}
  cli c address && address=${__CLI_C[address]}

  cli s r && record=${__CLI_S[r]}
  cli c record && record=${__CLI_C[record]}

  info "Record:$(cli color bold cyan $record). Address:$(cli color bold cyan $address). Captcha:$(cli color bold cyan $captchaCode). DomainID:$(cli color bold cyan $domainID)"

  curl -X POST 'https://freedns.afraid.org/subdomain/save.php?step=2' \
  -b "./cookies.txt" \
  -c "./cookies.txt" \
  -d "type=$record" \
  -d "subdomain=$subdomain" \
  -d "domain_id=$domainID" \
  -d "address=$address" \
  -d 'ttlalias=' \
  -d 'wildcard=0' \
  -d 'ref=L3N1YmRvbWFpby8=' \
  -d "captcha_code=$captchaCode" \
  -d 'send=Save!' \
  -o "./freedns_subdomain_creation_response.html" \
  -L --silent 
  
  grep -q 'The security code was incorrect, please try again' './freedns_subdomain_creation_response.html' && error "The captcha $(cli color bold red "$captchaCode") was wrong. Try again"
  grep -q "The hostname <b>$subdomain.$domain</b> is already taken!" './freedns_subdomain_creation_response.html' && error "The domain $(cli color bold cyan "$subdomain").$(cli color bold yellow "$domain") is already taken by someone else."
  grep -q '<TITLE>Problems!</TITLE>' './freedns_subdomain_creation_response.html' && error "Unable to create the subdomain $(cli color bold cyan "$subdomain").$(cli color bold yellow "$domain") for unknown reassons
 
Make sure you are logged in
"

  rm './freedns_subdomain_creation_response.html'
  exit "Subdomain $(cli color bold cyan "$subdomain").$(cli color bold yellow "$domain") created"

}







subdomainList() {
  # Descargar la página de subdominios
  info "Fetching subdomains list..."
  
  curl 'https://freedns.afraid.org/subdomain/' \
    -b "./cookies.txt" \
    -c "./cookies.txt" \
    -o "./subdomain_list.html" \
    -L --silent >/dev/null 2>&1

  # Verificar si estamos autenticados usando el patrón correcto
  if ! grep -q '<td bgcolor="#eeeeee">UserID:</td><td bgcolor="#eeeeee" align="right">' "./subdomain_list.html"; then
    rm -f "./subdomain_list.html"
    error "Not authenticated. Please login first with: ./freedns.sh account login -e email -p password"
  fi

  info "User is authenticated"

  # Extraer el número total de subdominios
  local total_subdomains=$(grep -o '>[[:space:]]*[0-9]*[[:space:]]*subdomains' "./subdomain_list.html" | grep -o '[0-9]*' | head -1)

  if [[ -z "$total_subdomains" ]] || [[ "$total_subdomains" -eq 0 ]]; then
    warning "No subdomains found"
    showAccountInfo
    rm -f "./subdomain_list.html"
    return
  fi

  info "Found $total_subdomains subdomain(s) in your account"
  
  echo ""
  echo "$(cli color bold cyan "Your Subdomains") ($total_subdomains total)"
  echo "$(cli color bold white "==================================================================")"
  
  # Extraer información de la cuenta
  showAccountInfo
  
  # Extraer la tabla de subdominios completa
  # Buscar desde <form action=delete2.php> hasta </form>
  local table_content=$(awk '/<form action=delete2.php>/,/<\/form>/' "./subdomain_list.html")
  
  if [[ -z "$table_content" ]]; then
    # Si no encontramos con ese patrón, buscar cualquier tabla que contenga "subdomains"
    table_content=$(grep -A 200 "subdomains</font>" "./subdomain_list.html" | head -100)
  fi
  
  # Procesar la tabla línea por línea
  local current_domain=""
  local subdomain_count=0
  local in_subdomain_row=0
  local temp_subdomain=""
  local temp_type=""
  local temp_value=""
  
  # Primero, normalizar el contenido: reemplazar >< con >\n< para separar etiquetas
  echo "$table_content" | sed 's/></>\n</g' | while IFS= read -r line; do
    # Buscar dominios (aparecen en líneas como: <td>chickenkiller.com</td>)
    if [[ "$line" =~ ^\<td\>[a-zA-Z0-9.-]+\</td\>$ ]]; then
      current_domain=$(echo "$line" | sed 's/<td>//;s/<\/td>//')
      if [[ -n "$current_domain" ]] && [[ ! "$current_domain" =~ ^[0-9]+$ ]] && [[ ! "$current_domain" =~ edit_domain_id ]]; then
        echo ""
        echo "  Domain: $(cli color bold yellow "$current_domain")"
        echo "  $(cli color bold white "----------------------------------")"
      fi
      continue
    fi
    
    # Buscar enlaces de subdominios (contienen data_id)
    if [[ "$line" =~ data_id ]] && [[ "$line" =~ \>([a-zA-Z0-9.-]+)\</a\> ]]; then
      temp_subdomain="${BASH_REMATCH[1]}"
      in_subdomain_row=1
      continue
    fi
    
    # Si estamos en una fila de subdominio, buscar tipo y valor
    if [[ $in_subdomain_row -eq 1 ]]; then
      # Buscar tipo de registro (A, TXT, URL, etc.)
      if [[ "$line" =~ ^\<td\ bgcolor=\#eeeeee\>[A-Z]+\</td\>$ ]]; then
        temp_type=$(echo "$line" | sed 's/<td bgcolor=#eeeeee>//;s/<\/td>//')
        continue
      fi
      
      # Buscar valor del registro
      if [[ "$line" =~ ^\<td\ bgcolor=\#eeeeee\> ]]; then
        temp_value=$(echo "$line" | sed 's/<td bgcolor=#eeeeee>//;s/<\/td>//')
        temp_value=$(echo "$temp_value" | sed 's/&quot;/"/g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g')
        
        # Ahora tenemos todos los datos del subdominio
        if [[ -n "$temp_subdomain" ]] && [[ -n "$current_domain" ]] && [[ "$temp_subdomain" =~ \.$current_domain$ ]]; then
          local subdomain_name="${temp_subdomain%.$current_domain}"
          
          # Color según tipo de registro
          local type_color="cyan"
          case "$temp_type" in
            "A"|"AAAA") type_color="green" ;;
            "CNAME") type_color="blue" ;;
            "MX"|"TXT") type_color="yellow" ;;
            "URL") type_color="magenta" ;;
            *) type_color="cyan" ;;
          esac
          
          echo "    • $(cli color bold "$subdomain_name").$(cli color yellow "$current_domain")"
          echo "      Type: $(cli color $type_color "$temp_type") | Value: $(cli color bold white "$temp_value")"
          
          subdomain_count=$((subdomain_count + 1))
          
          # Resetear variables temporales
          temp_subdomain=""
          temp_type=""
          temp_value=""
          in_subdomain_row=0
        fi
      fi
    fi
  done
  
  # Si el método anterior no funcionó, usar un método más directo con awk
  if [[ $subdomain_count -eq 0 ]]; then
    echo ""
    info "Using direct parsing method..."
    
    # Extraer todos los data_id y procesarlos
    grep -o 'data_id=[0-9]\+' "./subdomain_list.html" | sort -u | while read -r data_id_line; do
      local data_id="${data_id_line#data_id=}"
      
      # Buscar la línea que contiene este data_id y extraer información
      awk -v id="$data_id" '
      BEGIN { found=0; domain=""; subdomain=""; type=""; value="" }
      /<td>[a-zA-Z0-9.-]+<\/td>/ { 
        if ($0 !~ /edit_domain_id/) {
          gsub(/<td>|<\/td>/,"",$0)
          if ($0 ~ /\./) domain=$0
        }
      }
      /data_id=/ && $0 ~ id {
        found=1
        # Extraer subdominio
        if (match($0, />([a-zA-Z0-9.-]+)</, arr)) {
          subdomain=arr[1]
        }
      }
      found && /<td bgcolor=#eeeeee>[A-Z]+<\/td>/ {
        gsub(/<td bgcolor=#eeeeee>|<\/td>/,"",$0)
        type=$0
      }
      found && /<td bgcolor=#eeeeee>/ && $0 !~ /[A-Z]+<\/td>/ {
        gsub(/<td bgcolor=#eeeeee>|<\/td>/,"",$0)
        gsub(/&quot;/,"\"",$0)
        gsub(/&amp;/,"\\&",$0)
        value=$0
        if (domain && subdomain && type) {
          print domain "|" subdomain "|" type "|" value
          found=0
        }
      }
      ' "./subdomain_list.html" | while IFS='|' read -r domain subdomain record_type record_value; do
        if [[ -n "$domain" ]] && [[ -n "$subdomain" ]]; then
          if [[ "$current_domain" != "$domain" ]]; then
            current_domain="$domain"
            echo ""
            echo "  Domain: $(cli color bold yellow "$current_domain")"
            echo "  $(cli color white "----------------------------------")"
          fi
          
          local subdomain_name="${subdomain%.$current_domain}"
          local type_color="cyan"
          case "$record_type" in
            "A"|"AAAA") type_color="green" ;;
            "CNAME") type_color="blue" ;;
            "MX"|"TXT") type_color="yellow" ;;
            "URL") type_color="magenta" ;;
            *) type_color="cyan" ;;
          esac
          
          echo "    • $(cli color bold white "$subdomain_name").$(cli color yellow "$current_domain")"
          echo "      Type: $(cli color $type_color "$record_type") | Value: $(cli color white "$record_value")"
          
          subdomain_count=$((subdomain_count + 1))
        fi
      done
    done
  fi
  
  # Limpiar archivo
  rm -f "./subdomain_list.html"
  
  echo ""
  echo "$(cli color bold white "==================================================================")"
  
  if [[ $subdomain_count -gt 0 ]]; then
    success "Successfully listed $subdomain_count subdomain(s)"
  else
    warning "No subdomains could be extracted"
    info "The HTML structure might have changed. Please report this issue."
  fi
  
  echo ""
  info "Tip: Use $(cli color bold cyan "./freedns.sh subdomain available") to see all available domains for creating new subdomains"
}

# Función auxiliar para mostrar información de la cuenta
showAccountInfo() {
  # Extraer UserID - método más robusto
  local user_id=""
  local account_type=""
  
  # Buscar la tabla de información de cuenta
  awk '
  /UserID:/ { 
    for(i=1; i<=10; i++) {
      getline line
      if (match(line, /<td bgcolor="#eeeeee"[^>]*>([^<]+)</, arr)) {
        print "USER:" arr[1]
        break
      }
    }
  }
  /Account Type:/ { 
    for(i=1; i<=10; i++) {
      getline line
      if (match(line, /<td bgcolor="#eeeeee"[^>]*>([^<]+)</, arr)) {
        print "TYPE:" arr[1]
        break
      }
    }
  }
  ' "./subdomain_list.html" | while read -r line; do
    if [[ "$line" =~ ^USER: ]]; then
      user_id="${line#USER:}"
    elif [[ "$line" =~ ^TYPE: ]]; then
      account_type="${line#TYPE:}"
    fi
  done
  
  if [[ -n "$user_id" ]]; then
    info "Account: $(cli color cyan "$user_id") ($account_type)"
  fi
}










subdomainList() {
  # Descargar la página de subdominios
  info "Fetching subdomains list..."
  
  curl 'https://freedns.afraid.org/subdomain/' \
    -b "./cookies.txt" \
    -c "./cookies.txt" \
    -o "./subdomain_list.html" \
    -L --silent >/dev/null 2>&1

  # Verificar si estamos autenticados
  if ! grep -q '<td bgcolor=#eeeeee>UserID:</td><td bgcolor=#eeeeee align=right>' "./subdomain_list.html"; then
    rm -f "./subdomain_list.html"
    error "Not authenticated. Please login first with: ./freedns.sh account login -e email -p password"
  fi

  info "User is authenticated"

  # Extraer el número total de subdominios del título de la tabla
  local total_subdomains=$(grep -o '>[[:space:]]*[0-9]*[[:space:]]*subdomains' "./subdomain_list.html" | grep -o '[0-9]*' | head -1)

  if [[ -z "$total_subdomains" ]] || [[ "$total_subdomains" -eq 0 ]]; then
    warning "No subdomains found"
    showAccountInfo
    rm -f "./subdomain_list.html"
    return
  fi

  info "Found $total_subdomains subdomain(s) in your account"
  
  echo ""
  echo "$(cli color bold cyan "Your Subdomains") ($total_subdomains total)"
  echo "$(cli color bold white "==================================================================")"
  
  # Extraer información de la cuenta
  showAccountInfo
  
  # Método directo: procesar el HTML limpiándolo primero
  echo ""
  
  # Extraer solo la parte de la tabla que nos interesa
  sed -n '/<form action=delete2.php>/,/<\/form>/p' "./subdomain_list.html" | \
    sed 's/></>\n</g' | \
    grep -E '^<td>|<a href=edit.php?data_id|^<td bgcolor=#eeeeee>' | \
    while IFS= read -r line; do
      # Si es un dominio (ej: <td>chickenkiller.com</td>)
      if [[ "$line" == "<td>"*"</td>" ]] && [[ ! "$line" =~ "add" ]] && [[ ! "$line" =~ "edit_domain_id" ]]; then
        local domain="${line#<td>}"
        domain="${domain%</td>}"
        if [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
          echo ""
          echo "  Domain: $(cli color bold yellow "$domain")"
          echo "  $(cli color white "----------------------------------")"
          continue
        fi
      fi
      
      # Si es un enlace a subdominio (contiene data_id)
      if [[ "$line" == *"data_id"* ]] && [[ "$line" == *"</a>"* ]]; then
        # Extraer el dominio completo
        local full_domain="${line#*>}"
        full_domain="${full_domain%</a>*}"
        echo "    Found: $full_domain"
      fi
    done
  
  # Ahora, método más robusto: usar awk para procesar bloques
  echo ""
  info "Detailed list:"
  
  # Extraer la tabla completa
  local table_content=$(awk '/<form action=delete2.php>/,/<\/form>/' "./subdomain_list.html")
  
  # Procesar bloques: cada dominio y sus subdominios
  local current_domain=""
  
  # Primero, extraer todos los dominios
  echo "$table_content" | grep -o '<td>[a-zA-Z0-9.-]*</td>' | \
    grep -v 'edit_domain_id' | \
    sed 's/<td>//g; s/<\/td>//g' | \
    while read -r domain; do
      [[ -n "$domain" ]] && echo "DOMAIN: $domain"
    done
  
  # Método final: extraer todo en un formato estructurado
  echo ""
  echo "$(cli color bold white "Detailed Subdomain Information:")"
  echo ""
  
  # Usar sed para extraer la información estructurada
  # Patrón: dominio, luego subdominios con sus tipos y valores
  local in_domain_block=false
  local temp_domain=""
  local temp_subdomain=""
  local temp_type=""
  local temp_value=""
  local subdomain_count=0
  
  # Leer línea por línea el archivo original
  while IFS= read -r line; do
    # Buscar inicio de bloque de dominio
    if [[ "$line" =~ \<td\>[a-zA-Z0-9.-]+\</td\> ]] && [[ ! "$line" =~ edit_domain_id ]] && [[ ! "$line" =~ "add" ]]; then
      temp_domain=$(echo "$line" | sed 's/<td>//;s/<\/td>//')
      if [[ -n "$temp_domain" ]]; then
        echo ""
        echo "  Domain: $(cli color bold yellow "$temp_domain")"
        echo "  $(cli color white "----------------------------------")"
        in_domain_block=true
      fi
    fi
    
    # Si estamos en un bloque de dominio, buscar subdominios
    if [[ "$in_domain_block" == true ]] && [[ "$line" =~ data_id ]]; then
      # Extraer el subdominio completo
      if [[ "$line" =~ \>([a-zA-Z0-9.-]+)\</a\> ]]; then
        temp_subdomain="${BASH_REMATCH[1]}"
        
        # Extraer tipo - buscar en la misma línea
        if [[ "$line" =~ \<td\ bgcolor=#eeeeee\>([A-Z]+)\</td\> ]]; then
          temp_type="${BASH_REMATCH[1]}"
        fi
        
        # Extraer valor - buscar en la misma línea después del tipo
        if [[ "$line" =~ \<td\ bgcolor=#eeeeee\>([^<]+)\</td\>.*$ ]] && [[ ! "${BASH_REMATCH[1]}" =~ ^[A-Z]+$ ]]; then
          temp_value="${BASH_REMATCH[1]}"
          temp_value=$(echo "$temp_value" | sed 's/&quot;/"/g; s/&amp;/\&/g')
        fi
        
        # Si tenemos todos los datos, mostrar
        if [[ -n "$temp_subdomain" ]] && [[ -n "$temp_type" ]] && [[ -n "$temp_value" ]]; then
          # Extraer solo el nombre del subdominio (sin el dominio)
          local subdomain_name="${temp_subdomain%.$temp_domain}"
          
          # Color según tipo
          local type_color="cyan"
          case "$temp_type" in
            "A"|"AAAA") type_color="green" ;;
            "CNAME") type_color="blue" ;;
            "MX"|"TXT") type_color="yellow" ;;
            "URL") type_color="magenta" ;;
            *) type_color="cyan" ;;
          esac
          
          echo "    • $(cli color bold "$subdomain_name").$(cli color yellow "$temp_domain")"
          echo "      Type: $(cli color $type_color "$temp_type") | Value: $(cli color white "$temp_value")"
          
          subdomain_count=$((subdomain_count + 1))
          
          # Resetear variables temporales
          temp_subdomain=""
          temp_type=""
          temp_value=""
        fi
      fi
    fi
    
    # Si encontramos el siguiente dominio, terminar el bloque actual
    if [[ "$line" =~ \<td\ bgcolor=#cccccc ]] && [[ -n "$temp_domain" ]]; then
      in_domain_block=false
    fi
  done < "./subdomain_list.html"
  
  # Si no extrajimos con el método anterior, hacer una extracción simple
  if [[ $subdomain_count -eq 0 ]]; then
    echo ""
    info "Using simple extraction method..."
    
    # Extraer líneas que contienen subdominios completos
    grep -o '>[a-zA-Z0-9.-]*\.[a-zA-Z0-9.-]*\.[a-zA-Z]\{2,\}</a>' "./subdomain_list.html" | \
      sed 's/>//;s/<\/a>//' | \
      sort -u | \
      while read -r full_domain; do
        # Extraer dominio y subdominio
        local domain_part="${full_domain#*.}"
        local subdomain_name="${full_domain%%.*}"
        echo "    • $subdomain_name.$domain_part"
        subdomain_count=$((subdomain_count + 1))
      done
  fi
  
  # Limpiar archivo
  rm -f "./subdomain_list.html"
  
  echo ""
  echo "$(cli color bold white "==================================================================")"
  
  if [[ $subdomain_count -gt 0 ]]; then
    success "Successfully listed $subdomain_count subdomain(s)"
  else
    warning "No subdomains could be extracted"
  fi
  
  echo ""
  info "Tip: Use $(cli color bold cyan "./freedns.sh subdomain available") to see all available domains for creating new subdomains"
}

# Función auxiliar para mostrar información de la cuenta
showAccountInfo() {
  # Extraer UserID usando grep directo
  local user_id=$(grep -A1 '<td bgcolor=#eeeeee>UserID:</td>' "./subdomain_list.html" | tail -1 | sed 's/<[^>]*>//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
  
  # Extraer Account Type
  local account_type=$(grep -A1 '<td bgcolor=#eeeeee>Account Type:</td>' "./subdomain_list.html" | tail -1 | sed 's/<[^>]*>//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
  
  if [[ -n "$user_id" ]]; then
    info "Account: $(cli color cyan "$user_id") ($account_type)"
  fi
}
















subdomainEdit() {
  warning "Not implemented"
}

subdomainDelete() {
  warning "Not implemented"
}

cmd=$(cli o | sed -n '1p')
subcmd=$(cli o | sed -n '2p')
subsubcmd=$(cli o | sed -n '3p')

if      cli noArgs                 ;then    showUsage                 ;fi
if cli s h || cli c help           ;then    showUsage                 ;fi
if cli s v || cli c verbose        ;then    verbose=true              ;fi
if cli s d || cli c debug          ;then    debug=true                ;fi 
if            cli c version        ;then    exit "$version"           ;fi


if [[ $cmd =~ ^account$        ]]  ;then
  if [[ $subcmd =~ ^create$    ]]  ;then    accountCreate             ;elif 
     [[ $subcmd =~ ^login$     ]]  ;then    accountLogin              ;elif
     [[ $subcmd =~ ^status$    ]]  ;then    accountStatus             ;elif
     [[ $subcmd =~ ^logout$    ]]  ;then    accountLogout             ;elif
     [[ $subcmd =~ ^edit$      ]]  ;then    accountEdit               ;elif
     [[ $subcmd =~ ^delete$    ]]  ;then    accountDelete             ;else
     [[    -z $subcmd          ]]    &&     error "You need to provide a subcommand" ||
       error "The subcommand $(cli color bold red $subcmd) is not valid for $(cli color bold green account)" ;
  fi 

elif [[ $cmd =~ ^domain$       ]]  ;then  
  if [[ $subcmd =~ ^create$    ]]  ;then    domainCreate              ;elif
     [[ $subcmd =~ ^list$      ]]  ;then    domainList                ;elif
     [[ $subcmd =~ ^delete$    ]]  ;then    domainDelete              ;elif
     [[ $subcmd =~ ^edit$      ]]  ;then    domainEdit                ;else
     [[    -z $subcmd          ]]    &&     error "You need to provide a subcommand" ||
       error "The subcommand $(cli color bold red $subcmd) is not valid for $(cli color bold green domain)" ;
  fi

elif [[ $cmd =~ ^subdomain$    ]]  ;then
  if [[ $subcmd =~ ^available$ ]]  ;then    subdomainAvailable        ;elif
     [[ $subcmd =~ ^create$    ]]  ;then    subdomainCreate           ;elif
     [[ $subcmd =~ ^list$      ]]  ;then    subdomainList             ;elif
     [[ $subcmd =~ ^delete$    ]]  ;then    subdomainDelete           ;elif
     [[ $subcmd =~ ^edit$      ]]  ;then    subdomainEdit             ;else
     [[    -z $subcmd          ]]    &&     error "You need to provide a subcommand" ||
       error "The subcommand $(cli color bold red $subcmd) is not valid for $(cli color bold green subdomain)" ;
  fi

elif [[ $cmd =~ ^help$         ]]  ;then    showUsage 

else
  error "The command $(cli color bold red $cmd) is not a valid command"
fi


