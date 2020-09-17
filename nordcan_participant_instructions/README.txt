
## Beta instructions

### Beta contact info

We are available on the NORDCAN slack if you encounter a problem with our
R packages or if you have questions about the call for data or other
NORDCAN matters. We ask the participants _not_ to send e-mail concerning these
matters because we want all the information in one place.

Link to NORDCAN Slack: https://cancerregistr-hhd6843.slack.com
Please discuss testing under the channel #testing.
If you need to be invited to Slack (you cannot join our Slack despite logging
into your account), contact siri.laronningen@kreftregisteret.no.

### Beta timeline

We ask that you complete the beta testing by Wednesday 2020-09-23. "Completing"
means running through the R script and either ending up with the end results
as intended, or encountering a problem which cannot be resolved without a
patch on the R packages. Please contact the R package authors on the NORDCAN
slack if you encounter problems or unexpected results.

Link to NORDCAN Slack: https://cancerregistr-hhd6843.slack.com
Please discuss testing under the channel #testing.
If you need to be invited to Slack (you cannot join our Slack despite logging
into your account), contact siri.laronningen@kreftregisteret.no.

### Datasets in beta

For this beta, you only need to have the columns marked "NORDCAN" in the
"Mandatory NORDCAN/JRC" column in the table under "Call for data - Incidence".
The JRC-only columns are not used anywhere in our current system. If applicable,
any column that you don't have at all in your data, you should mark missing for
all records (e.g. grade may not be available for all participants). For other
datasets you should collect all columns as requested.

### What to expect

In this beta test we mainly want to see how far we can get with the current
versions of our R packages. It is expected that something will not work as
intended. If R emits any errors or warnings, contact the package authors.
Let us also know if the results make very little sense to you. We will look
at the actual resulting statistics more carefully in the next release.

## Files and folders

### File nordcan.R

This script guides you through the whole process of computing NORDCAN statistics
once you have the NORDCAN datasets loaded into R. It's best to read through
this script first before doing anything else so you get an idea of what is
required of you.

### File nordcan_call_for_data_manual.html

This .html file contains the descriptions of the NORDCAN datasets. Use this
to guide you to collect your datasets for compiling NORDCAN statistics.

### Folder pkgs

Contains R packages you need to install. See nordcan.R for how to do that.

