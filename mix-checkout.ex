defmodule Mix.Tasks.Checkout do
  use Mix.Task

  @moduledoc """
    Mix task which runs migrations when switching branches.
    Usage: `mix checkout branch-name`
  """

  def run(new_branch) do
    old_branch = current_branch()
    log("On branch #{old_branch}")

    new_branch = new_branch |> List.first

    {:ok, old_migrations} = File.ls("priv/repo/migrations")

    log("Checking out #{new_branch}...")
    {_, status_code} = checkout(new_branch)
    halt_for_git_errors(status_code)

    {:ok, new_migrations} = File.ls("priv/repo/migrations")

    if List.last(old_migrations) == List.last(new_migrations) do
      log("#{old_branch} and #{new_branch} are at the same migration, done.")
    else
      run_migrations(old_branch, new_branch, old_migrations, new_migrations)
    end
  end

  def run_migrations(old_branch, new_branch, old_migrations, new_migrations) do
    common_ancestor_name = MapSet.intersection(
        MapSet.new(old_migrations),
        MapSet.new(new_migrations)
      )
        |> MapSet.to_list
        |> Enum.sort
        |> List.last

    common_ancestor_version =
      common_ancestor_name
        |> String.split("_")
        |> List.first

    log("Common Ancestor: #{common_ancestor_name}")

    log("Switch back to #{old_branch} to roll it back...")
    checkout(old_branch)

    log("Rolling back to: #{common_ancestor_version}...")
    rollback_to(common_ancestor_version)

    log("Checking out #{new_branch}...")
    checkout(new_branch)

    log("Migrating...")
    migrate()

    log("Done!")
  end

  defp rollback_to(version) do
    System.cmd("mix", ["ecto.rollback", "--to", version])
  end

  defp migrate do
    System.cmd("mix", ["ecto.migrate"])
  end

  defp current_branch do
    {res, _} = System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"])
    res |> String.trim
  end

  defp checkout(branch_name) do
    System.cmd("git", ["checkout", branch_name])
  end

  # git has a status code 1 when error, 0 when ok.
  defp halt_for_git_errors(status_code) do
    if status_code == 1, do: System.halt(0)
  end

  defp log(msg) do
    IO.puts IO.ANSI.format([
      :yellow,
      :bright,
      :black_background,
      msg], true
    )
  end
end
