require 'spec/spec_helper'

describe 'Role' do
  describe 'inheritance' do
    TEST_ROLES = [ :role1, :role2, :role3 ]
    attr_reader :superuser, *TEST_ROLES

    before(:each) do
      @superuser = Role[:superuser]
      TEST_ROLES.each do | n |
        r = Role[n] ||
        Role.create!(:name => "#{n}", :description => "#{n} #{__FILE__}")
        instance_variable_set("@#{n}", r)
        # debugger
        # r.parent_roles
        r.parent_roles.to_a.should == [ ]
        r.child_roles.to_a.should == [ ]
      end
    end

    after(:each) do
      TEST_ROLES.each do | n |
        r = instance_variable_get("@#{n}")
        r && r.destroy
        RoleInheritance.count(:conditions => [ 'child_role_id = ? OR parent_role_id = ?', r, r ]).should == 0
      end
    end

    describe 'defaults' do
      it 'should not have any role_inheritances' do
        superuser.role_inheritances.to_a.should == [ ]
      end
      
      it 'should not have any parent_roles' do
        superuser.parent_roles.to_a.should == [ ]
      end
      
      it 'should be its own ancestor' do
        superuser.parent_roles_deep.to_a.should == [ superuser ]
      end
      
      it 'should not have any child_roles' do
        superuser.child_roles.to_a.should == [ ]
      end
      
      it 'should be its own decendent' do
        superuser.child_roles_deep.to_a.should == [ superuser ]
      end
    end # describe

    describe 'cyclicality' do
      it 'should not allow immediate cyclical inheritance' do
        role = role1
        lambda {
          RoleInheritance.create!(:parent_role => role, :child_role => role)
        }.should raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Child role cannot be its own ancestor')
      end
      
      it 'should not allow deep cyclical inheritance' do
        RoleInheritance.create!(:parent_role => role1, :child_role => role2)
        RoleInheritance.create!(:parent_role => role2, :child_role => role3)
        role3.parent_roles_deep.to_a.should == [ role3, role2, role1 ] 
        lambda {
          RoleInheritance.create!(:parent_role => role3, :child_role => role1)
        }.should raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Child role cannot be its own ancestor')
      end
    end # describe

    describe 'addition' do
      it 'should handle parent_roles.push ' do
        role1.parent_roles.to_a.should == [ ]
        role1.parent_roles.push role2
        role1.parent_roles.to_a.should == [ role2 ]
        role1.reload
        role2.reload
        role1.parent_roles_deep.to_a.should == [ role1, role2 ]
        role2.child_roles.to_a.should == [ role1 ]
        role2.child_roles_deep.to_a.should == [ role2, role1 ]
      end
      
      it 'should handle child_roles.push ' do
        role1.child_roles.to_a.should == [ ]
        role1.child_roles.push role2
        role1.child_roles.to_a.should == [ role2 ]
        role1.reload
        role2.reload
        role1.child_roles_deep.to_a.should == [ role1, role2 ]
        role2.parent_roles.to_a.should == [ role1 ]
        role2.parent_roles_deep.to_a.should == [ role2, role1 ]
      end
    end # describe

    describe 'deletion' do
      it 'should handle parent_roles.delete ' do
        role1.parent_roles.to_a.should == [ ]
        role1.parent_roles.push(role2, role3)
        role1.parent_roles_deep.to_a.should == [ role1, role2, role3 ]
        role2.child_roles.to_a.should == [ role1 ]
        role2.child_roles_deep.to_a.should == [ role2, role1 ]

        role1.parent_roles.delete(role2)
        role1.parent_roles.to_a.should == [ role3 ]
        role2.child_roles.to_a.should == [ ]
        role3.child_roles.to_a.should == [ role1 ]
      end
      
      it 'should handle child_roles.delete ' do
        role1.child_roles.to_a.should == [ ]
        role1.child_roles.push(role2, role3)
        role1.child_roles_deep.to_a.should == [ role1, role2, role3 ]
        role2.parent_roles.to_a.should == [ role1 ]
        role2.parent_roles_deep.to_a.should == [ role2, role1 ]

        role1.child_roles.delete(role2)
        role1.child_roles.to_a.should == [ role3 ]
        role2.parent_roles.to_a.should == [ ]
        role3.parent_roles.to_a.should == [ role1 ]
      end
    end # describe

  end # describe
end # describe
