#!/bin/sh

# More info about DNS blacklists look at https://www.dnsbl.com/

dnsbl_list=""

dnsbl_list="$dnsbl_list b.barracudacentral.org"
dnsbl_url_b_barracudacentral_org="http://www.barracudacentral.org/"
dnsbl_response_b_barracudacentral_org_2_0_0_127="BARRACUDACENTRAL"

dnsbl_list="$dnsbl_list spamsources.fabel.dk"
dnsbl_url_spamsources_fabel_dk="https://www.spamsources.fabel.dk/"
dnsbl_response_spamsources_fabel_dk_2_0_0_127="FABELSOURCES"

#dnsbl_list="$dnsbl_list forbidden.icm.edu.pl"
#dnsbl_url_forbidden_icm_edu_pl="http://sunsite.icm.edu.pl/spam/bh.html"
#dnsbl_response_forbidden_icm_edu_pl_2_0_0_127="ICMFORBIDDEN"

dnsbl_list="$dnsbl_list dnsbl.kempt.net"
dnsbl_url_dnsbl_kempt_net="http://www.kempt.net/spam-policy.html"
dnsbl_response_dnsbl_kempt_net_2_0_0_127="KEMPTBL"

dnsbl_list="$dnsbl_list spamguard.leadmon.net"
dnsbl_url_spamguard_leadmon_net="http://www.leadmon.net/spamguard"
dnsbl_response_spamguard_leadmon_net_2_0_0_127="LNSGDUL"
dnsbl_response_spamguard_leadmon_net_3_0_0_127="LNSGSRC"
dnsbl_response_spamguard_leadmon_net_4_0_0_127="LNSGBULK"
dnsbl_response_spamguard_leadmon_net_5_0_0_127="LNSGSGOR"
dnsbl_response_spamguard_leadmon_net_6_0_0_127="LNSGMULTI"
dnsbl_response_spamguard_leadmon_net_7_0_0_127="LNSGBLOCK"

dnsbl_list="$dnsbl_list virus.rbl.msrbl.net"
dnsbl_url_virus_rbl_msrbl_net="https://www.msrbl.com/"
dnsbl_response_virus_rbl_msrbl_net_2_0_0_127="MSRBL-VIRUS"

dnsbl_list="$dnsbl_list phishing.rbl.msrbl.net"
dnsbl_url_phishing_rbl_msrbl_net="https://www.msrbl.com/"
dnsbl_response_phishing_rbl_msrbl_net_2_0_0_127="MSRBL-PHISHING"

dnsbl_list="$dnsbl_list images.rbl.msrbl.net"
dnsbl_url_images_rbl_msrbl_net="https://www.msrbl.com/"
dnsbl_response_images_rbl_msrbl_net_2_0_0_127="MSRBL-IMAGES"

dnsbl_list="$dnsbl_list spam.rbl.msrbl.net"
dnsbl_url_spam_rbl_msrbl_net="https://www.msrbl.com/"
dnsbl_response_spam_rbl_msrbl_net_2_0_0_127="MSRBL-SPAM"

dnsbl_list="$dnsbl_list psbl.surriel.com"
dnsbl_url_psbl_surriel_com="http://psbl.surriel.com/"
dnsbl_response_psbl_surriel_com_2_0_0_127="PSBL"

dnsbl_list="$dnsbl_list zen.spamhaus.org"
dnsbl_url_zen_spamhaus_org="https://www.spamhaus.org/zen/"
dnsbl_response_zen_spamhaus_org_2_0_0_127="SBL"
dnsbl_response_zen_spamhaus_org_3_0_0_127="CSS"
dnsbl_response_zen_spamhaus_org_4_0_0_127="XBL"
dnsbl_response_zen_spamhaus_org_5_0_0_127="XBL"
dnsbl_response_zen_spamhaus_org_6_0_0_127="XBL"
dnsbl_response_zen_spamhaus_org_7_0_0_127="XBL"
dnsbl_response_zen_spamhaus_org_10_0_0_127="PBL"
dnsbl_response_zen_spamhaus_org_11_0_0_127="PBL"

dnsbl_list="$dnsbl_list rbl.schulte.org"
dnsbl_url_rbl_schulte_org="http://rbl.schulte.org/"
dnsbl_response_rbl_schulte_org_2_0_0_127="SCHULTE"

dnsbl_list="$dnsbl_list korea.services.net"
dnsbl_url_korea_services_net="http://korea.services.net"
dnsbl_response_korea_services_net_2_0_0_127="SERVICESNET"

dnsbl_list="$dnsbl_list dnsbl.sorbs.net"
dnsbl_url_dnsbl_sorbs_net="http://www.us.sorbs.net/using.shtml"
dnsbl_response_dnsbl_sorbs_net_2_0_0_127="SORBS-HTTP"
dnsbl_response_dnsbl_sorbs_net_3_0_0_127="SORBS-SOCKS"
dnsbl_response_dnsbl_sorbs_net_4_0_0_127="SORBS-MISC"
dnsbl_response_dnsbl_sorbs_net_5_0_0_127="SORBS-SMTP"
dnsbl_response_dnsbl_sorbs_net_6_0_0_127="SORBS-SPAM"
dnsbl_response_dnsbl_sorbs_net_7_0_0_127="SORBS-WEB"
dnsbl_response_dnsbl_sorbs_net_8_0_0_127="SORBS-BLOCK"
dnsbl_response_dnsbl_sorbs_net_9_0_0_127="SORBS-ZOMBIE"
dnsbl_response_dnsbl_sorbs_net_10_0_0_127="SORBS-DUHL"
dnsbl_response_dnsbl_sorbs_net_11_0_0_127="SORBS-BADCONF"
dnsbl_response_dnsbl_sorbs_net_12_0_0_127="SORBS-NOMAIL"
dnsbl_response_dnsbl_sorbs_net_14_0_0_127="SORBS-NOSERVER"
dnsbl_response_dnsbl_sorbs_net_15_0_0_127="SORBS-VIRUS"

dnsbl_list="$dnsbl_list bl.spamcop.net"
dnsbl_url_bl_spamcop_net="http://spamcop.net/bl.shtml"
dnsbl_response_bl_spamcop_net_2_0_0_127="SPAMCOP"

dnsbl_list="$dnsbl_list dnsbl-1.uceprotect.net"
dnsbl_url_dnsbl_1_uceprotect_net="http://www.uceprotect.net"
dnsbl_response_dnsbl_1_uceprotect_net_2_0_0_127="UCEPROTECTL1"

dnsbl_list="$dnsbl_list dnsbl-2.uceprotect.net"
dnsbl_url_dnsbl_2_uceprotect_net="http://www.uceprotect.net"
dnsbl_response_dnsbl_2_uceprotect_net_2_0_0_127="UCEPROTECTL2"

dnsbl_list="$dnsbl_list dnsbl-3.uceprotect.net"
dnsbl_url_dnsbl_3_uceprotect_net="http://www.uceprotect.net"
dnsbl_response_dnsbl_3_uceprotect_net_2_0_0_127="UCEPROTECTL3"

reverse_ipv4() {
	echo -n "$1" \
		| sed -Ee 's/^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/\4.\3.\2.\1/g'
}

escape_dns() {
	echo -n "$1" \
		| sed -e 's/[.-]/_/g'
}

check_ip() {
	revip=`reverse_ipv4 "$1"`

	for dnsbl in $dnsbl_list ; do
		responses=`dig +short -t A "$revip.$dnsbl" | grep "127.0.0."`
		if [ "$responses" = "" ] ; then
			continue
		fi

		dnsbl_escaped=`escape_dns "$dnsbl"`
		dnsbl_url="dnsbl_url_${dnsbl_escaped}"
		responses_reversed=`reverse_ipv4 "$responses"`
		responses_escaped=`escape_dns "$responses_reversed"`

		for response_escaped in $responses_escaped ; do
			dnsbl_response="dnsbl_response_${dnsbl_escaped}_${response_escaped}"
			eval "echo \${$dnsbl_url} \${$dnsbl_response}"
		done
	done
}

check_ip "$1"
