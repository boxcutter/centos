require_relative 'spec_helper'

describe 'box' do
  it 'should have a root user' do
    expect(user 'root').to exist
  end

  it 'should have a vagrant user' do
    expect(user 'vagrant').to exist
  end

  it 'should not have a .vbox_version file' do
    expect(file '/home/vagrant/.vbox_version').to_not be_file
  end
end
