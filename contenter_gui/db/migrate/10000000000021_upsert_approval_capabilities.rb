# This migration will be run on production where existing capabilities need to be 
# dropped and readded (or, if RI doesn't permit dropping, modified in place)
# In dev/int, the seeder task will take care of populating it
class UpsertApprovalCapabilities < ActiveRecord::Migration
  def self.up
    if RAILS_ENV != 'development'
      # were redefining this so delete its old caps
      begin
        cr = Role[:content_releaser]
        cr.role_capabilities.each(&:destroy)
        cr.destroy
      rescue 
      end

      # A small bit of duplication of seeder code to migrate existing
      # capabilities to the new structure.
      newrcs=[
              [ 'superuser',
                nil,
                [ 
                 'controller/*/*/*',
                ],
              ],
         [ 'content_approver',
           'Can move content into the approved state, for moving to contenter_integration files',
           [
            'controller/workflow/index',
            'controller/workflow/perform_status_action',
            'controller/workflow/perform_status_action/approve',
           ],
         ],

         [ 'content_releaser',
           'Can move content into the released state, for moving to contenter_production files',
           [
            'controller/workflow/index',
            'controller/workflow/perform_status_action',
            'controller/workflow/perform_status_action/release',
           ],
         ]
      ]

      Role.build_role_capability *newrcs

    end
  end

  def self.down
    [:content_releaser, :content_approver].each do |rs|
      r = Role[rs]
      r.role_capabilities.each(&:destroy)
      r.destroy
    end
  end
end
