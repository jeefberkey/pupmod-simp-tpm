require 'spec_helper'

describe 'tpm' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
          :cmdline => {'foo' => 'bar'},
          :has_tpm => false
        })
      end

      ### init.pp
      context 'with default parameters and no physical TPM' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.to create_class('tpm::ima') }
        it { is_expected.not_to create_class('tpm::ownership') }
        it { is_expected.not_to contain_package('tpm-tools') }
        it { is_expected.not_to contain_package('trousers') }
        it { is_expected.not_to contain_service('tcsd') }
        # it { is_expected.not_to contain_class('::tpm::ima::policy') }
        it { is_expected.not_to contain_mount('/sys/kernel/security') }
        it { is_expected.not_to contain_reboot_notify('ima_log') }
      end

      context 'with default parameters and a detected TPM' do
        let(:facts) do
          os_facts.merge({ :has_tpm => true })
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.not_to create_class('tpm::ownership') }
        it { is_expected.to contain_package('tpm-tools').with_ensure('installed') }
        it { is_expected.to contain_package('trousers').with_ensure('installed') }
        it { is_expected.to contain_service('tcsd').with({
          'ensure'  => 'running',
          'enable'  => true,
        }) }
      end

      context 'with detected TPM and take_ownership => true' do
        let(:facts) do
          os_facts.merge({ :has_tpm => true })
        end
        let(:params) {{ :take_ownership => true }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.to create_class('tpm::ownership') }
        it { is_expected.to contain_package('tpm-tools').with_ensure('installed') }
        it { is_expected.to contain_package('trousers').with_ensure('installed') }
        it { is_expected.to contain_service('tcsd').with({
          'ensure'  => 'running',
          'enable'  => true,
        }) }
      end

      context 'ima' do
        let(:facts) do
          facts[:cmdline] = { 'ima' => 'on' }
          facts[:ima_log_size] = 29000000
          # facts
        end

        context 'should tell the user to reboot when the ima log is filling up' do
          let(:facts) do
            facts[:ima_log_size] = 50000002
            # facts
          end
          let(:params) {{ :ima_log_max_size => 50000000 }}

          it { is_expected.to contain_reboot_notify('ima_log') }
        end

        context 'should only manage ima policy when asked' do
          let(:params) {{
            :manage_ima_policy => true,
            :enable            => true,
          }}
          it do
            skip('This is commented out for compatability reasons, like read-only filesystems')
            is_expected.to contain_class('::tpm::ima::policy')
          end
        end

        context 'without_ima_enabled' do
          let(:facts) do
            facts[:cmdline] = { 'foo' => 'bar' }
            facts[:ima_log_size] = 29000000
            # facts
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_file(params[:mount_dir]) }
          it { is_expected.to contain_reboot_notify('ima_reboot') }
          it { is_expected.to contain_kernel_parameter('ima').with_value('on') }
          it { is_expected.to contain_kernel_parameter('ima').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_audit').with_value(false) }
          it { is_expected.to contain_kernel_parameter('ima_audit').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_template').with_value(params[:ima_template]) }
          it { is_expected.to contain_kernel_parameter('ima_template').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_hash').with_value(params[:ima_hash]) }
          it { is_expected.to contain_kernel_parameter('ima_hash').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_tcb') }
        end

        context 'disabling_ima' do
          let(:params) {{ :enable => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_reboot_notify('ima_reboot') }
          it { is_expected.to contain_kernel_parameter('ima').with_ensure('absent') }
          it { is_expected.to contain_kernel_parameter('ima').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_audit').with_ensure('absent') }
          it { is_expected.to contain_kernel_parameter('ima_audit').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_template').with_ensure('absent') }
          it { is_expected.to contain_kernel_parameter('ima_template').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_hash').with_ensure('absent') }
          it { is_expected.to contain_kernel_parameter('ima_hash').with_bootmode('normal') }
          it { is_expected.to contain_kernel_parameter('ima_tcb').with_ensure('absent') }
        end

      end

    end
  end
end
