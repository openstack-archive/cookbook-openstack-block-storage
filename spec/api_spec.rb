#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'
    include_examples 'creates_cinder_conf', 'service[apache2]', 'cinder', 'cinder', 'restart'

    it do
      expect(chef_run).to create_file('/etc/apache2/conf-available/cinder-wsgi.conf').with(
        owner: 'root',
        group: 'www-data',
        mode: '0640',
        content: '# Chef openstack-block-storage: file to block config from package'
      )
    end

    it do
      expect(chef_run).to upgrade_package %w(python3-cinder cinder-api)
    end

    it 'upgrades mysql python3 package' do
      expect(chef_run).to upgrade_package('python3-mysqldb')
    end

    it 'runs db migrations' do
      expect(chef_run).to run_execute('cinder-manage db sync').with(user: 'cinder', group: 'cinder')
    end

    describe 'apache wsgi' do
      let(:file) { '/etc/apache2/sites-available/cinder-api.conf' }

      it do
        expect(chef_run).to create_template(file).with(
          source: 'wsgi-template.conf.erb',
          variables: {
            daemon_process: 'cinder-wsgi',
            group: 'cinder',
            log_dir: '/var/log/apache2',
            run_dir: '/var/lock',
            server_entry: '/usr/bin/cinder-wsgi',
            server_host: '127.0.0.1',
            server_port: '8776',
            user: 'cinder',
          }
        )
      end
      it 'configures cinder-api.conf' do
        [
          /VirtualHost 127.0.0.1:8776/,
          /WSGIDaemonProcess cinder-wsgi processes=2 threads=10 user=cinder group=cinder display-name=%{GROUP}/,
          /WSGIProcessGroup cinder-wsgi/,
          %r{WSGIScriptAlias / /usr/bin/cinder-wsgi},
          %r{ErrorLog /var/log/apache2/cinder-wsgi_error.log},
          %r{CustomLog /var/log/apache2/cinder-wsgi_access.log combined},
          %r{WSGISocketPrefix /var/lock},
        ].each do |line|
          expect(chef_run).to render_file(file).with_content(line)
        end
        expect(chef_run).to_not render_file(file).with_content(/SSLEngine On/)
      end
      it do
        expect(chef_run.template(file)).to notify('service[apache2]').to(:restart)
      end

      it do
        expect(chef_run).to install_apache2_install('openstack').with(listen: %w(127.0.0.1:8776))
      end

      it do
        expect(chef_run).to create_apache2_mod_wsgi('openstack')
      end

      it do
        expect(chef_run).to_not enable_apache2_module('ssl')
      end

      it do
        expect(chef_run).to disable_apache2_conf('cinder-wsgi')
      end

      it do
        expect(chef_run).to enable_apache2_site('cinder-api')
      end

      it do
        expect(chef_run.apache2_site('cinder-api')).to notify('service[apache2]').to(:restart).immediately
      end
      context 'Enable SSL' do
        cached(:chef_run) do
          node.override['openstack']['block-storage']['ssl']['enabled'] = true
          node.override['openstack']['block-storage']['ssl']['certfile'] = 'certfile'
          node.override['openstack']['block-storage']['ssl']['keyfile'] = 'keyfile'
          node.override['openstack']['block-storage']['ssl']['ca_certs_path'] = 'ca_certs_path'
          node.override['openstack']['block-storage']['ssl']['protocol'] = 'protocol'
          runner.converge(described_recipe)
        end
        it do
          expect(chef_run).to enable_apache2_module('ssl')
        end
        it 'configures cinder-api.conf' do
          [
            /SSLEngine On/,
            /SSLCertificateFile certfile/,
            /SSLCertificateKeyFile keyfile/,
            /SSLCACertificatePath ca_certs_path/,
            /SSLProtocol protocol/,
          ].each do |line|
            expect(chef_run).to render_file(file).with_content(line)
          end
          [
            /SSLCertificateChainFile/,
            /SSLCipherSuite/,
            /SSLVerifyClient/,
          ].each do |line|
            expect(chef_run).to_not render_file(file).with_content(line)
          end
        end
        context 'Enable chainfile, ciphers & cert_required' do
          cached(:chef_run) do
            node.override['openstack']['block-storage']['ssl']['enabled'] = true
            node.override['openstack']['block-storage']['ssl']['chainfile'] = 'chainfile'
            node.override['openstack']['block-storage']['ssl']['ciphers'] = 'ciphers'
            node.override['openstack']['block-storage']['ssl']['cert_required'] = true
            runner.converge(described_recipe)
          end
          it 'configures cinder-api.conf' do
            [
              /SSLCertificateChainFile chainfile/,
              /SSLCipherSuite ciphers/,
              /SSLVerifyClient require/,
            ].each do |line|
              expect(chef_run).to render_file(file).with_content(line)
            end
          end
        end
      end
    end

    describe 'policy file' do
      it 'does not manage policy file unless specified' do
        expect(chef_run).not_to create_remote_file('/etc/cinder/policy.json')
      end
      context 'policy file specified' do
        cached(:chef_run) do
          node.override['openstack']['block-storage']['policyfile_url'] = 'http://server/mypolicy.json'
          runner.converge(described_recipe)
        end
        let(:remote_policy) { chef_run.remote_file('/etc/cinder/policy.json') }

        it 'manages policy file when remote file is specified' do
          expect(chef_run).to create_remote_file('/etc/cinder/policy.json').with(
            user: 'cinder',
            group: 'cinder',
            mode: '644'
          )
        end
      end
    end
  end
end
