#!/bin/bash

########################################################
#                                                      #
#  libbash.sh French translation                       #
#                                                      #
#  Author: Jean Prunneaux (http://jean.prunneaux.com)  #
#                                                      #
########################################################

################################
#                              #
#  Version 0.1.0 (2017-01-19)  #
#                              #
################################

# This file must be included after libbash.sh:
# source "/path/to/libbash/libbash.sh"
# source "/path/to/libbash/locales/fr.sh"

# translation for default labels
lb_default_result_ok_label="... Terminé!"
lb_default_result_failed_label="... Échoué!"
lb_default_ok_label="OK"
lb_default_cancel_label="Annuler"
lb_default_cancel_shortlabel="a"
lb_default_yes_label="Oui"
lb_default_no_label="Non"
lb_default_yes_shortlabel="o"
lb_default_no_shortlabel="n"
lb_default_pwd_label="Mot de passe :"
lb_default_pwd_confirm_label="Confirmer le mot de passe :"
lb_default_chopt_label="Choisissez une option :"
lb_default_chdir_label="Choisissez un dossier :"
lb_default_chfile_label="Choisissez un fichier :"
lb_default_debug_label="DEBUG"
lb_default_info_label="INFO"
lb_default_warning_label="AVERTISSEMENT"
lb_default_error_label="ERREUR"
lb_default_critical_label="CRITIQUE"

# reset log levels
lb_loglevels=("$lb_default_critical_label" "$lb_default_error_label" "$lb_default_warning_label" "$lb_default_info_label" "$lb_default_debug_label")
