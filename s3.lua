#!/usr/bin/env simplecli

-- The remote current working directory
cwd = "/"
bucket = ""

function banner()
    return "S3 Shell"
end

function prompt()
    return cwd .. "> "
end

function s3path()
    return string.format("s3://%s%s", bucket, cwd)
end

help_bucket = "Set the S3 bucket to use"
function do_bucket(args)
    cli_variable("bucket", args[1])
end

help_profile = "Set the AWS credentials profile to use"
function do_profile(args)
    cli_envvar("AWS_PROFILE", args[1])
end

help_cd = "Change the current (s3) working directory"
function do_cd(args)
    cli_cd("cwd", args[1])
end

help_ls = "List the files stored in s3"
function do_ls(args)
    os.execute(t("aws s3 ls {{s3path}}{{args[1]}}"))
end

help_lls = "Local ls command. List local files."
function do_lls(args)
    os.execute("ls")
end

help_cat = "View a file stored in S3"
function do_cat(args, tempfile)
    os.execute(t("aws s3 cp {{s3path}}{{args[1]}} {{tempfile}}"))
    os.execute(t("cat {{tempfile}}"))
end

help_edit = "Edit a file in s3"
function do_edit(args, tempfile)
    os.execute(t("aws s3 cp {{s3path}}{{args[1]}} {{tempfile}}"))
    modified = cli_edit(tempfile)
    if modified then
        os.execute(t("aws s3 cp {{tempfile}} {{s3path}}{{args[1]}}"))
    end
end

function do_vi(args, tempfile)
    do_edit(args, tempfile)
end

function do_vim(args, tempfile)
    do_edit(args, tempfile)
end

help_get = "Download a file from s3"
function do_get(args)
    os.execute(t("aws s3 cp {{s3path}}{{args[1]}} ."))
end

help_rm = "Remove a file from s3"
function do_rm(args)
    os.execute(t("aws s3 rm {{s3path}}{{args[1]}}"))
end

help_cp = "Copy files in s3"
function do_cp(args)
    os.execute(t("aws s3 cp {{s3path}}{{args[1]}} {{s3path}}{{args[2]}}"))
end

help_mv = "Move files in s3"
function do_mv(args)
    os.execute(t("aws s3 mv {{s3path}}{{args[1]}} {{s3path}}{{args[2]}}"))
end
