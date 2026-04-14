import re

def is_valid_domain_format(domain):
    # Cek apakah domain sesuai dengan pola domain yang valid
    pattern = re.compile(
        r'^(?:[a-zA-Z0-9]' # Alphanumeric character
        r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)' # Subdomain
        r'+[a-zA-Z]{2,6}$' # Domain extension
    )
    return bool(pattern.match(domain))

def check_domain_formats(file_path):
    with open(file_path, 'r') as file:
        domains = file.readlines()
    
    invalid_domains = []
    for domain in domains:
        domain = domain.strip()
        if not is_valid_domain_format(domain):
            invalid_domains.append(domain)
    
    return invalid_domains

# Path ke file yang ingin diperiksa
file_path = "/root/buildgeo/domain-list-community/my-custom/mahavpn-easylist"
invalid_domains = check_domain_formats(file_path)

if invalid_domains:
    print("Domain tidak valid ditemukan:")
    for domain in invalid_domains:
        print(domain)
else:
    print("Semua domain valid.")