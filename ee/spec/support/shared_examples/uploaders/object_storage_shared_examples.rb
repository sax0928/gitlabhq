shared_context 'with storage' do |store, **stub_params|
  before do
    subject.object_store = store
  end
end

shared_examples "migrates" do |to_store:, from_store: nil|
  let(:to) { to_store }
  let(:from) { from_store || subject.object_store }

  def migrate(to)
    subject.migrate!(to)
  end

  def checksum
    Digest::SHA256.hexdigest(subject.read)
  end

  before do
    migrate(from)
  end

  it 'does nothing when migrating to the current store' do
    expect { migrate(from) }.not_to change { subject.object_store }.from(from)
  end

  it 'migrate to the specified store' do
    from_checksum = checksum

    expect { migrate(to) }.to change { subject.object_store }.from(from).to(to)
    expect(checksum).to eq(from_checksum)
  end

  it 'removes the original file after the migration' do
    original_file = subject.file.path
    migrate(to)

    expect(File.exist?(original_file)).to be_falsey
  end

  it 'can access to the original file during migration' do
    original_file = subject.file.path

    allow(subject).to receive(:delete_migrated_file) { }

    expect { migrate(to) }.not_to change { File.exist?(original_file) }
  end

  context 'when migrate! is not oqqupied by another process' do
    it 'executes migrate!' do
      expect(subject).to receive(:object_store=)

      migrate(to)
    end
  end

  context 'when migrate! is oqqupied by another process' do
    let(:exclusive_lease_key) { "object_storage_migrate:#{subject.store_path}" }

    before do
      @uuid = Gitlab::ExclusiveLease.new(exclusive_lease_key, timeout: 1.hour.to_i).try_obtain
    end

    it 'does not execute migrate!' do
      expect(subject).not_to receive(:object_store=)

      migrate(to)
    end

    after do
      Gitlab::ExclusiveLease.cancel(exclusive_lease_key, @uuid)
    end
  end

  context 'migration is unsuccessful' do
    shared_examples "handles gracefully" do |error:|
      it 'does not update the object_store' do
        expect { migrate(to) }.to raise_error(error)
        expect(subject.object_store).to eq(from)
      end

      it 'does not delete the original file' do
        expect { migrate(to) }.to raise_error(error)
        expect(subject.exists?).to be_truthy
      end
    end

    context 'when the store is not supported' do
      let(:to) { -1 } # not a valid store

      include_examples "handles gracefully", error: ObjectStorage::UnknownStoreError
    end

    context 'upon a fog failure' do
      before do
        storage_class = subject.send(:storage_for, to).class
        expect_any_instance_of(storage_class).to receive(:store!).and_raise("Store failure.")
      end

      include_examples "handles gracefully", error: "Store failure."
    end

    context 'upon a database failure' do
      before do
        expect(uploader).to receive(:persist_object_store!).and_raise("ActiveRecord failure.")
      end

      include_examples "handles gracefully", error: "ActiveRecord failure."
    end
  end
end
