
## Beta instructions

### To beta participants

Thank you for participating in the NORDCAN beta! Yes we NORDCAN!

### Third beta release info

After additional bugfixes we are close to the first official release.
This is the last planned beta before the official call for data mid-November.
It is absolutely paramount that participants look at the results they get
and the results of the comparison to NORDCAN 8.2 statistics. This is the last
good chance to make changes if something is amiss.

Due to fixes in prevalence computing the statistics will take longer than in the
previous beta. Preprocessing may take 10-20 minutes, but computing all the
statistics can take 3.5 hours of computation time in total.

We ask that you have completed the computations and report on any suspicious
differences between the beta results and NORDCAN 8.2 statistics on Wednesday,
November 4th at the latest. At a minimum we ask that you inspect comparison
results where p_value_bh < 0.01. Notes for comparisons:

- it was not possible to programmatically compare the new survival to NORDCAN
  8.2 survival, so this time comparisons must be done manually. you should at
  a minimum compare to the results for your country available on
  https://www-dep.iarc.fr/nordcan/english/Table23_sel.asp
  (5-year survival). note that e.g. the latest period in 8.2 was 2012-2016 but
  now 2014-2018. therefore the new estimates are likely slightly higher. pay
  attention especially to sites whose 5-year survival trend has plateaued,
  because there any differences are more likely due to issues in the new
  survivals than in sites that have not plateaued.
- entity 456 (Other and unspecified leukaemias) did not exist in 8.2 but an
  entity was given that number by mistake in the 8.2 datasets sent to
  participants. see the comparison section in nordcan.R.
- there have been some changes in the entities. see section
  Specification Entities in the manual.

### Beta contact info

We are available on the NORDCAN slack if you encounter a problem with our
R packages or if you have questions about the call for data or other
NORDCAN matters. We ask the participants _not_ to send e-mail concerning these
matters because we want all the information in one place.

Link to NORDCAN Slack: https://cancerregistr-hhd6843.slack.com
Please discuss testing under the channel #testing.
If you need to be invited to Slack (you cannot join our Slack despite logging
into your account), contact siri.laronningen@kreftregisteret.no.

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

