class AddColumnsForHelmTillerCertificates < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :clusters_applications_helm, :ca_key, :text
    add_column :clusters_applications_helm, :ca_cert, :text
    add_column :clusters_applications_helm, :client_key, :text
    add_column :clusters_applications_helm, :client_cert, :text
    add_column :clusters_applications_helm, :server_key, :text
    add_column :clusters_applications_helm, :server_cert, :text
  end
end
