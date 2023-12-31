# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

provider_class = Puppet::Type.type(:postgresql_conf).provider(:parsed)

describe provider_class do
  let(:title) { 'postgresql_conf' }
  let(:provider) do
    conf_class = Puppet::Type.type(:postgresql_conf)
    provider = conf_class.provider(:parsed)
    conffile = tmpfilename('postgresql.conf')
    allow_any_instance_of(provider).to receive(:target).and_return conffile # rubocop:disable RSpec/AnyInstance
    provider
  end

  after :each do
    provider.initvars
  end

  describe 'simple configuration that should be allowed' do
    it 'parses a simple ini line' do
      expect(provider.parse_line("listen_addreses = '*'")).to eq(
        name: 'listen_addreses', value: '*', comment: nil, record_type: :parsed,
      )
    end

    it 'parses a simple ini line (2)' do
      expect(provider.parse_line("   listen_addreses = '*'")).to eq(
        name: 'listen_addreses', value: '*', comment: nil, record_type: :parsed,
      )
    end

    it 'parses a simple ini line (3)' do
      expect(provider.parse_line("listen_addreses = '*' # dont mind me")).to eq(
        name: 'listen_addreses', value: '*', comment: 'dont mind me', record_type: :parsed,
      )
    end

    it 'parses a comment' do
      expect(provider.parse_line('# dont mind me')).to eq(
        line: '# dont mind me', record_type: :comment,
      )
    end

    it 'parses a comment (2)' do
      expect(provider.parse_line(" \t# dont mind me")).to eq(
        line: " \t# dont mind me", record_type: :comment,
      )
    end

    it 'allows includes' do
      expect(provider.parse_line('include puppetextra')).to eq(
        name: 'include', value: 'puppetextra', comment: nil, record_type: :parsed,
      )
    end

    it 'allows numbers through without quotes' do
      expect(provider.parse_line('wal_keep_segments = 32')).to eq(
        name: 'wal_keep_segments', value: '32', comment: nil, record_type: :parsed,
      )
    end

    it 'allows blanks through' do
      expect(provider.parse_line('')).to eq(
        line: '', record_type: :blank,
      )
    end

    it 'parses keys with dots' do
      expect(provider.parse_line('auto_explain.log_min_duration = 1ms')).to eq(
        name: 'auto_explain.log_min_duration', value: '1ms', comment: nil, record_type: :parsed,
      )
    end
  end

  describe 'configuration that should be set' do
    it 'sets comment lines' do
      expect(provider.to_line(line: '# dont mind me', record_type: :comment)).to eq(
        '# dont mind me',
      )
    end

    it 'sets blank lines' do
      expect(provider.to_line(line: '', record_type: :blank)).to eq(
        '',
      )
    end

    it 'sets simple configuration' do
      expect(provider.to_line(name: 'listen_addresses', value: '*', comment: nil, record_type: :parsed)).to eq(
        "listen_addresses = '*'",
      )
    end

    it 'sets simple configuration with period in name' do
      expect(provider.to_line(name: 'auto_explain.log_min_duration', value: '100ms', comment: nil, record_type: :parsed)).to eq(
        'auto_explain.log_min_duration = 100ms',
      )
    end

    it 'sets simple configuration even with comments' do
      expect(provider.to_line(name: 'listen_addresses', value: '*', comment: 'dont mind me', record_type: :parsed)).to eq(
        "listen_addresses = '*' # dont mind me",
      )
    end

    it 'quotes includes' do
      expect(provider.to_line(name: 'include', value: 'puppetextra', comment: nil, record_type: :parsed)).to eq(
        "include 'puppetextra'",
      )
    end

    it 'quotes multiple words' do
      expect(provider.to_line(name: 'archive_command', value: 'rsync up', comment: nil, record_type: :parsed)).to eq(
        "archive_command = 'rsync up'",
      )
    end

    it 'does not quote numbers' do
      expect(provider.to_line(name: 'wal_segments', value: '32', comment: nil, record_type: :parsed)).to eq(
        'wal_segments = 32',
      )
    end

    it 'allows numbers' do
      expect(provider.to_line(name: 'integer', value: 42, comment: nil, record_type: :parsed)).to eq(
        'integer = 42',
      )
    end

    it 'allows floats' do
      expect(provider.to_line(name: 'float', value: 2.71828182845, comment: nil, record_type: :parsed)).to eq(
        'float = 2.71828182845',
      )
    end

    it 'quotes single string address' do
      expect(provider.to_line(name: 'listen_addresses', value: '0.0.0.0', comment: nil, record_type: :parsed)).to eq(
        "listen_addresses = '0.0.0.0'",
      )
    end

    it 'quotes an array of addresses' do
      expect(provider.to_line(name: 'listen_addresses', value: ['0.0.0.0', '127.0.0.1'], comment: nil, record_type: :parsed)).to eq(
        "listen_addresses = '0.0.0.0, 127.0.0.1'",
      )
    end
  end
end
