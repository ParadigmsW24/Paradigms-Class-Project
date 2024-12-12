defmodule TermProject.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  defmodule TermProject.Repo.Migrations.CreateUsersTable do
    use Ecto.Migration

    def change do
      create table(:users) do
        add :email, :string, null: false
        add :full_name, :string
        add :password, :string, virtual: true
        add :password_hash, :string
        add :token, :string
        add :auth_provider, :string, default: "regular"

        timestamps()
      end


      create unique_index(:users, [:email])
    end
  end

end
