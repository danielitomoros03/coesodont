class NestedDependencyValidator < ActiveModel::Validator
  def validate(record)
    if nested_dependency(record)
      record.errors.add "Prelación #{record.id}", 'anidada.'
    end
  end

  private
    def nested_dependency(record)
      tree = record.prelate_subject.full_dependency_tree_ids
      (tree.include? record.depend_subject_id)
    end    
end
