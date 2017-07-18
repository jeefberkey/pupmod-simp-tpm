# Enabling this class will take ownership of the TPM in the system,
# using an auto-generated password created with simplib's passgen.
#
# The password must be generated with passgen in order for most of the facts
# to be functional post-ownership, as the tpm commands from tpm-tools
# require the owner password.
#
# @param owner_pass The TPM owner password
#
# @param srk_pass The TPM SRK password. This is defaulted to an empty
#   because according to the [trousers documentation](http://trousers.sourceforge.net/pkcs11.html)
#   it needs to be null to be useful.
#
# @param advanced_facts This option will enable facts that require
#   the owner password to function. The password will be on the client
#   filesystem (in `$vardir/simp`) if enabled.
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm::ownership {
  assert_private()

  $owner_pass     = $tpm::owner_pass
  $srk_pass       = $tpm::srk_pass
  $advanced_facts = $tpm::advanced_facts

  tpm_ownership { 'tpm0':
    ensure         => present,
    owner_pass     => $owner_pass,
    srk_pass       => $srk_pass,
    advanced_facts => $advanced_facts
  }

}
