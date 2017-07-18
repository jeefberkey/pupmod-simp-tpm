# Create a launch policy, modify grub, and enable tboot
class tpm::tboot {
  assert_private()

  include 'tpm::tboot::policy'
  include 'tpm::tboot::grub'

  Class['tpm']
  -> Class['tpm::tboot::policy']
  -> Class['tpm::tboot::grub']

}
