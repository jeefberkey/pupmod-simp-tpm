# Provides utilities for interacting with a TPM
#
# @param ima Toggles IMA on or off.
#
# @param take_ownership Enable to allow Puppet to take ownership
#   of the TPM.
#
# @author Nick Markowski <nmarkowski@keywcorp.com>
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm (
  Boolean $take_ownership = false,
  String  $owner_pass     = passgen( "${facts['fqdn']}_tpm0_owner_pass", { 'length' => 20 } ),
  String  $srk_pass       = 'well-known',
  Boolean $advanced_facts = false,

  Boolean              $tboot = false,
  String               $sinit_path = 'puppet:///modules/tpm/sinit/sinit.bin',
  Stdlib::AbsolutePath $tboot_policy_script        = '/root/txt/create-lcp-tboot-policy.sh',
  String               $tboot_policy_script_source = 'puppet:///modules/tpm/create-lcp-tboot-policy.sh',
  Array[String]        $tboot_boot_options         = ['logging=serial,memory,vga'],
  Array[String]        $additional_boot_options    = ['intel_iommu=on'],

  Boolean              $ima               = false,
  Boolean              $manage_ima_policy = false,
  Stdlib::AbsolutePath $mount_dir         = '/sys/kernel/security',
  Boolean              $ima_audit         = true,
  Tpm::Ima::Template   $ima_template      = 'ima-ng',
  String               $ima_hash          = 'sha256',
  Boolean              $ima_tcb           = true,
  Integer              $ima_log_max_size      = 30000000,

  String $pkcs11_so_pin   = passgen( "${facts['fqdn']}_pkcs_so_pin", { 'length' => 8 } ),
  String $pkcs11_user_pin = passgen( "${facts['fqdn']}_pkcs_user_pin", { 'length' => 8 } ),

  String $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {

  # Check if the system has a TPM (which also checks that it
  # is a physical machine, and if so install tools and setup
  # tcsd service
  if $facts['has_tpm'] {
    package { 'tpm-tools': ensure => $package_ensure }
    package { 'trousers':  ensure => $package_ensure }

    service { 'tcsd':
      ensure  => 'running',
      enable  => true,
      require => Package['tpm-tools'],
    }

    if $take_ownership {
      include '::tpm::ownership'
    }
  }

  include '::tpm::ima'

}
