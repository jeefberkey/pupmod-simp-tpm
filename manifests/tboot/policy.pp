# Generate and install policy
class tpm::tboot::policy {
  assert_private()

  $owner_password       = $tpm::owner_password
  $policy_script        = $tpm::tboot_policy_script
  $policy_script_source = $tpm::tboot_policy_script_source

  file { $policy_script:
    ensure => file,
    source => $policy_script_source
  }

  if ! $facts['tboot_successful'] {
    exec { 'Generate and install tboot policy':
      command => "sh ${policy_script} ${owner_password}",
      tries   => 1
    }
  }

}
