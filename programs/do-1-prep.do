clear
cd "[XLS data folder]"
import excel using "vignette-data-raw_20220605.xlsx", first

**********************************************
** RENAMES, RECODES, AND SCALE CONSTRUCTION **
**********************************************

rename condtions1neutral2procedural tx
recode tx (1 2 3 = 0 "no bwc") (4 5 6 = 1 "bwc"), g(txbwc)
recode tx (1 4 = 1 "neutral") (2 5 = 2 "injustice") (3 6 = 3 "justice"), g(txtyp)
encode street, gen(clustid) lab(STREET)
label drop STREET
label var id "ID"
label var tx "TX"
label var txbwc "TX: BWC Presence"
label var txtyp "TX: Encounter Type"
label var clustid "CLUSTER: Street Seg"
label def TX 1 "neutr, no bwc" 2 "injust, no bwc" 3 "just, no bwc" 4 "neutr, bwc" 5 "injust, bwc" 6 "just, bwc"
label val tx TX
order id tx txbwc txtyp clustid, last

rename fairtreatment1stronglydisgar pjfair
rename respectfultreatment1strongly pjresp
rename factbaseddecision1stronglyd pjfact
rename voice1stronglydisgaree2disa pjvoic
rename trustworthiness1stronglydisga pjtrst
factor pjfair pjresp pjfact pjvoic pjtrst, pcf fac(1)
predict pjltnt
label var pjfair "PROC JUST: Fair"
label var pjresp "PROC JUST: Respectful"
label var pjfact "PROC JUST: Factual"
label var pjvoic "PROC JUST: Voice"
label var pjtrst "PROC JUST: Trustworthy"
label var pjltnt "PROC JUST: Prin Comp Fact"
order pjfair pjresp pjfact pjvoic pjtrst pjltnt, last

rename trust1stronglydisgaree2disa pltrst
rename confidence1stronglydisgaree2 plconf
rename respect1stronglydisgaree2di plresp
rename policedorightthing1strongly plrght
factor pltrst plconf plresp plrght, pcf fac(1)
predict plltnt
label var pltrst "POL LEGIT: Trust"
label var plconf "POL LEGIT: Confidence"
label var plresp "POL LEGIT: Respect"
label var plrght "POL LEGIT: Do Right"
label var plltnt "POL LEGIT: Prin Comp Fact"
order pltrst plconf plresp plrght plltnt, last

rename doingjobwell1stronglydisgar poleff
rename policelawfulness1stronglydis pollaw
label var poleff "POL EFFECT"
label var pollaw "POL LAWFUL"
order poleff pollaw, last

rename reportcrime1veryunlikely2u cprprt
rename reportdangeorousactivity1ver cpdang
rename reportsuspiciousactivity1ver cpsusp
rename informationsharing1veryunlik cpinfo
rename assistancetopolice1veryunl cpasst
factor cprprt cpdang cpsusp cpinfo cpasst, pcf fac(1)
predict cpltnt
label var cprprt "COOPERATE: Rep Crime"
label var cpdang "COOPERATE: Rep Dang Act"
label var cpsusp "COOPERATE: Rep Susp Act"
label var cpinfo "COOPERATE: Share Info"
label var cpasst "COOPERATE: Assistance"
label var cpltnt "COOPERATE: Prin Comp Fact"
order cprprt cpdang cpsusp cpinfo cpasst cpltnt, last

rename voluntarycompliancewithpolice sctold
rename AB scaccp
rename complywithpolice1stronglydi sccomp
factor sctold scaccp sccomp, pcf fac(1)
predict scltnt
label var sctold "SPEC COMPL: Do What Say"
label var scaccp "SPEC COMPL: Accept Tick"
label var sccomp "SPEC COMPL: Compelled"
label var scltnt "SPEC COMPL: Prin Comp Fact"
order sctold scaccp sccomp, last

rename complywithlaw1stronglydisga gencom
rename satisfactionwithpolice1stron gensat
rename satisfcationwithenounter1str encsat
rename relationwithpolice1veryunli polcom
label var gencom "GEN COMPL"
label var gensat "GEN SATIS"
label var encsat "ENC SATIS"
label var polcom "POL-COMM REL"
order gencom gensat encsat polcom, last

rename gender1male0female male
rename race1White0NonWhite white
rename employed1yes0no empl
rename voluntarycontact1yes0no polvol
rename Involuntarycontact1yes0no polinv
rename stopped1yes0no polstop
rename ticketed1yes0no poltick
rename BWCencounter1yes0no polbwc
rename yearofsurvey1Fall20192Fal wave
rename postFloyd1yes0no postfloyd
label var age "CONTROL: Age"
label var male "CONTROL: Male"
label var white "CONTROL: White"
label var empl "CONTROL: Employed"
label var polvol "CONTROL: Police Vol Cont"
label var polinv "CONTROL: Police Invol Cont"
label var polstop "CONTROL: Police Stopped"
label var poltick "CONTROL: Police Ticketed"
label var polbwc "CONTROL: Police BWC Enc"
order age male white empl polvol polinv polstop poltick polbwc, last

label var wave "TIME: Wave of Data Collection"
label var postfloyd "TIME: Post-Floyd"
label def WAVE 1 "fall 2019" 2 "fall 2021" 3 "spring 2022"
label val wave WAVE
order wave postfloyd, last

*******************************
** SAVE OUTFILE FOR ANALYSIS **
*******************************

keep id-postfloyd
compress
save "vignette-data-analyze.dta", replace
desc
