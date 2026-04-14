import requests
import re
import os

def download_and_filter_domains(url):
    response = requests.get(url)
    response.raise_for_status()  # Ensure we notice bad responses

    lines = response.text.splitlines()
    valid_domains = []

    ip_pattern = re.compile(r'^\d{1,3}(\.\d{1,3}){3}$')

    for line in lines:
        # Skip lines that contain "/"
        if "/" in line:
            continue
        # Check if line starts with "||" and contains "^"
        if line.startswith("||") and "^" in line:
            domain = line.split("^")[0][2:]  # Remove || and get the domain part
            if (not ip_pattern.match(domain) and 
                not domain.endswith(".")):  # Exclude IPs and domains ending with '.'
                valid_domains.append(domain)

    return valid_domains

def save_to_file(domains, filename, url):
    with open(filename, 'a') as file:  # Open file in append mode
        file.write(f"# konten {url}\n")  # Write the URL as a comment
        for domain in domains:
            file.write(domain + "\n")

if __name__ == "__main__":
    # Define the file path
    file_path = "my-custom/ads-customku"

    # Remove the file if it exists
    if os.path.exists(file_path):
        os.remove(file_path)

    urls = [
        "https://easylist.to/easylist/easylist.txt",
        "https://filters.adtidy.org/extension/ublock/filters/3.txt"
    ]

    for url in urls:
        valid_domains = download_and_filter_domains(url)
        save_to_file(valid_domains, file_path, url)

    print("Valid domains have been written to my-custom/ads-customku")