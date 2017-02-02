#!/usr/bin/env simplecli

domain = ""

function banner()
    return t("Route 53\nAWS Profile: {{AWS_PROFILE}}")
end

function prompt()
    return t("{{domain}}> ")
end

function do_profile(args)
    cli_envvar("AWS_PROFILE", args[1])
end

function do_domain(args)
    cli_variable("domain", args[1])
end

function zoneid()
    -- TODO - we might need to come up with a better way to do dynamic
    -- variables like this
    if _zone_id_domain == domain then
        return _zone_id
    end
    _zone_id_domain = domain
    f = assert(io.popen(t([[aws route53 list-hosted-zones |
        jq -r '.HostedZones[] | select(.Name == "{{domain}}.") | .Id']]), "r"))
    _zone_id = assert(f:read('*a'))
    _zone_id = string.gsub(_zone_id, "[\r\n]+", "")
    f:close()
    return _zone_id
end

help_zones = "List available route53 zones"
function do_zones()
    os.execute([[aws route53 list-hosted-zones |
        jq -r ".HostedZones[] | [.Id, .Name] | @tsv"]])
end

help_ls = [[List records for a domain.

Optionally filter on the given argument]]

function do_ls(args)
    os.execute(t([[
    aws route53 list-resource-record-sets --hosted-zone-id {{zoneid}} |
    jq -r '.ResourceRecordSets[] |
        select(.ResourceRecords != null) |
        select(.Name | contains("{{args[1]}}")) |
        .ResourceRecords[].Value as $value |
        [.Name, .TTL, .Type, $value] |
        @tsv'
    ]]))
end


help_rc=[[Create a new record or update an existing one

Usage: rc myrecord.example.com 300 A 1.2.3.4]]

function do_rc(args)
    os.execute(t([[aws route53 change-resource-record-sets \
    --hosted-zone-id {{zoneid}} \
    --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "{{args[1]}}",
                    "TTL": {{args[2]}},
                    "Type": "{{args[3]}}",
                    "ResourceRecords": [
                        {
                            "Value": "{{args[4]}}"
                        }
                    ]
                }
            }
        ]
    }' --output text]]))
end


help_rd =[[(Doesn't work yet) Delete a record from route53

Usage: rd myrecord.example.com 300 A]]

function do_rd(args)
    os.execute(t([[aws route53 change-resource-record-sets \
    --hosted-zone-id {{zoneid}} \
    --change-batch '{
        "Changes": [
            {
                "Action": "DELETE",
                "ResourceRecordSet": {
                    "Name": "{{args[1]}}",
                    "TTL": {{args[2]}},
                    "Type": "{{args[3]}}"
                }
            }
        ]
    }' --output text]]))
end


help_edit = [[Edit DNS records

Usage: edit SEARCHTERM]]

function do_edit(args, tempfile)
    os.execute(t([[aws route53 list-resource-record-sets \
        --hosted-zone-id {{zoneid}} |
        jq -r '[
            .ResourceRecordSets[] |
                select(.Name | contains("{{args[1]}}")) |
            {Action: "UPSERT", ResourceRecordSet: .}
        ] |
        {Changes: .}
        ' > {{tempfile}}
    ]]))

    modified = cli_edit(tempfile)

    if modified then
       os.execute(t([[aws route53 change-resource-record-sets \
        --hosted-zone-id {{zoneid}} \
        --change-batch file://{{tempfile}} \
        --output text]]))
    end
end