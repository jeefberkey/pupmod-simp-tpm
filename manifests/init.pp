# Provides utilities for interacting with a TPM
#
# @param use_ima [Boolean] Toggles IMA on or off.
#
# @param enable_pkcs_interface [Boolean] Use the TPM as a PKCS #11 interface
#
# @param take_ownership [Boolean] Enable to allow Puppet to take ownership
#   of the TPM.
#
# @author Nick Markowski <nmarkowski@keywcorp.com>
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm (
  $use_ima               = false,
  $enable_pkcs_interface = false,
  $take_ownership        = false
){
  validate_bool($use_ima)
  validate_bool($enable_pkcs_interface)
  validate_bool($take_ownership)

  # Check if the system has a TPM (which also checks that it
  # is a physical machine, and if so install tools and setup
  # tcsd service - uses str2bool because facts return as strings :(
  if str2bool($::has_tpm) {
    package { 'tpm-tools': ensure => latest }
    package { 'trousers': ensure => latest }

    service { 'tcsd':
      ensure  => 'running',
      enable  => true,
      require => Package['tpm-tools'],
    }

    if $enable_pkcs_interface {
      # TODO
      ##################################################################################################################
      # Here's a nice doc on how to set up the pkcs #11 interface
      # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-Encryption.html
      ##################################################################################################################
      # package { 'opencryptoki': ensure => latest }
      # package { 'opencryptoki-tpmtok': ensure => latest }
      package { 'tpm-tools-pkcs11': ensure => latest }

      # service { 'pkcsslotd':
      #   ensure => running,
      #   enable => true,
      # }
      # Initialize SO pin (note that the default SO PIN is 87654321):
      #   pkcsconf -c 0 -P
      #
      # Initialize User pin (use the SO PIN you just defined above):
      #   pkcsconf -c 0 -u
      #
      # Initialize the token:
      #   pkcsconf -c 0 -I
    }

    if $take_ownership {
      include '::tpm::ownership'
    }
  }

  if $use_ima {
    include '::tpm::ima'
  }

}
