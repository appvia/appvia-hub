module SluggedAttributeExamples
  RSpec.shared_examples 'slugged_attribute' do |attribute_name, presence:, uniqueness:, readonly:|
    it { is_expected.to validate_presence_of(attribute_name) } if presence

    if uniqueness
      if uniqueness.is_a?(Hash) && uniqueness.key?(:scope)
        scoped_attributes = Array(uniqueness[:scope])
        it { is_expected.to validate_uniqueness_of(attribute_name).scoped_to(*scoped_attributes) }
        it { is_expected.to have_db_index([attribute_name] + scoped_attributes).unique }
      else
        it { is_expected.to validate_uniqueness_of(attribute_name) }
        it { is_expected.to have_db_index(attribute_name).unique }
      end
    end

    it do
      is_expected.to allow_values(
        'f',
        'foo',
        'foo-bar',
        'foo-1',
        'f1obar',
        'foo-bar5'
      ).for(attribute_name)
    end

    it do
      is_expected.not_to allow_values(
        'FOO_1',
        'foo_bar',
        'fOO',
        'Foo',
        'foo bar',
        'foo 1',
        'foo_1',
        '1-foo',
        '1',
        '-foo',
        '_foo',
        'foo#1',
        'foo@1',
        '#1',
        '@1',
        'f123/bar'
      ).for(attribute_name)
    end

    if readonly
      it { is_expected.to have_readonly_attribute(attribute_name) }

      it 'is readonly (using update!)' do
        original_value = subject.send attribute_name
        subject.update! attribute_name => 'updated-value-should-not-work'
        expect(subject.reload.send(attribute_name)).to eq original_value
      end

      it 'is readonly (using save!)' do
        original_value = subject.send attribute_name
        subject.send "#{attribute_name}=", 'updated-value-should-not-work'
        subject.save!
        expect(subject.reload.send(attribute_name)).to eq original_value
      end
    end
  end
end
