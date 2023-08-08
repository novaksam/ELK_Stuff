# This pwoershell script generates a CSV file that can be used with
# the translate logstash plugin to obtain MAC address OUI infromation
#
# The max prefix length I've observed is 9 characters long, and the ruby code is designed to iterate up to that, based on if anything is found
# Example Logstash filter configuration:
####
# 	mutate {
#		id => "ECS - Mutate - Standardize MAC format"
#		uppercase => ["[client][mac]","[destination][mac]","[host][mac]","[observer][mac]","[server][mac]","[source][mac]"]
#		gsub => [
#			"[client][mac]", "[-:]", "",
#			"[destination][mac]", "[-:]", "",
#			"[host][mac]", "[-:]","",
#			"[observer][mac]", "[-:]", "",
#			"[server][mac]", "[-:]", "",
#			"[source][mac]", "[-:]", ""
#		]
#	}
#
# if [source][mac] {
#    ruby { code => "event.set('[source][mac_oui_hex]', event.get('[source][mac]')[0..5])" }
#    if [source][mac_oui_hex] {
#      translate {
#        id => "Enrich - ECS - Translate - source.mac -> source.mac_oui #1"
#        source => "[source][mac_oui_hex]"
#        target => "[source][mac_oui]"
#        dictionary_path => "C:\ELK\logstash\OUI_Merged.csv"
#        override => true
#        remove_field => "[source][mac_oui_hex]"
#        fallback => "OUI Not Found"
#      }
#    }
#    
#    if [source][mac_oui] == "OUI Not Found" {
#      ruby { code => "event.set('[source][mac_oui_hex]', event.get('[source][mac]')[0..6])"  }
#      if [source][mac_oui_hex] {
#        translate {
#          id => "Enrich - ECS - Translate - source.mac -> source.mac_oui #2"
#          source => "[source][mac_oui_hex]"
#          target => "[source][mac_oui]"
#          dictionary_path => "C:\ELK\logstash\OUI_Merged.csv"
#          override => true
#          remove_field => "[source][mac_oui_hex]"
#          fallback => "OUI Not Found"
#        }
#      }
#    }
#    
#    if [source][mac_oui] == "OUI Not Found" {
#      ruby { code => "event.set('[source][mac_oui_hex]', event.get('[source][mac]')[0..7])" }
#      if [source][mac_oui_hex] {
#        translate {
#          id => "Enrich - ECS - Translate - source.mac -> source.mac_oui #3"
#          source => "[source][mac_oui_hex]"
#          target => "[source][mac_oui]"
#          dictionary_path => "C:\ELK\logstash\macaddress.io-db.csv"
#          override => true
#          remove_field => "[source][mac_oui_hex]"
#          fallback => "OUI Not Found"
#        }
#      }
#    }
#    
#    if [source][mac_oui] == "OUI Not Found" {
#      ruby { code => "event.set('[source][mac_oui_hex]', event.get('[source][mac]')[0..8])" }
#      if [source][mac_oui_hex] {
#        translate {
#          id => "Enrich - ECS - Translate - source.mac -> source.mac_oui #4"
#          source => "[source][mac_oui_hex]"
#          target => "[source][mac_oui]"
#          dictionary_path => "C:\ELK\logstash\macaddress.io-db.csv"
#          override => true
#          remove_field => "[source][mac_oui_hex]"
#          fallback => "OUI Not Found"
#        }
#      }
#    }

Invoke-WebRequest -URI 'https://standards-oui.ieee.org/oui/oui.csv' -OutFile "$HOME\Downloads\oui.csv"
$csv1 = import-csv $HOME\Downloads\oui.csv -Encoding utf8 
Invoke-WebRequest -URI 'https://standards-oui.ieee.org/oui28/mam.csv' -OutFile "$HOME\Downloads\mam.csv"
$csv2 = import-csv $HOME\Downloads\mam.csv -Encoding utf8 
Invoke-WebRequest -URI 'https://standards-oui.ieee.org/oui36/oui36.csv' -OutFile "$HOME\Downloads\oui36.csv"
$csv3 = import-csv $HOME\downloads\oui36.csv -Encoding utf8 
Invoke-WebRequest -URI 'https://standards-oui.ieee.org/cid/cid.csv' -OutFile "$HOME\Downloads\cid.csv"
$csv4 = import-csv $HOME\Downloads\cid.csv -Encoding utf8 
Invoke-WebRequest -URI 'https://standards-oui.ieee.org/iab/iab.csv' -OutFile "$HOME\Downloads\iab.csv"
$csv5 = import-csv $HOME\Downloads\iab.csv -Encoding utf8 



$merged = $csv1 + $csv2 + $csv3 + $csv4 + $csv5
# Normalization; one limitation of \W is it included periods, so the org names look a little different
for ($i = 0; $i -lt $merged.count; $i++)
{
    $merged[$i].'Organization Address' = ($merged[$i].'Organization Address' -Replace '[\W]',' ').trim()
    $merged[$i].'Organization Name' = ($merged[$i].'Organization Name' -Replace '[\W]',' ').trim()
}
$merged | select-object Assignment,"Organization Name","Organization Address","Registry" | export-csv $HOME\Downloads\merged-OUI.csv -Encoding utf8 -QuoteFields "Organization Name","Organization Address"

Remove-Item -Path "$HOME\Downloads\oui.csv"
Remove-Item -Path "$HOME\Downloads\mam.csv"
Remove-Item -Path "$HOME\Downloads\oui36.csv"
Remove-Item -Path "$HOME\Downloads\cid.csv"
Remove-Item -Path "$HOME\Downloads\iab.csv"
