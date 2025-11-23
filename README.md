# Scope Predicate Linker

シンプルなプロジェクト/ラベル/タスクのスコープと、その組み合わせを試すサンプルアプリです。複雑なスコープはコメントアウトし、同名の `?` メソッドでフィルタリングを行う実装になっています。

## セットアップ
- Ruby 3.3系想定（`bundle check` で不足があれば `bundle install`）
- DB: SQLite（手元で `bin/rails db:setup` すればOK）

## 主要なスコープ／メソッド
- Task: `billable`（scope）、`overdue?`, `slipping?`, `on_track?`
- Label: `active`（scope）、`active?`, `risk_flags?`, `applied_to_billable_tasks?`
- Project: `active`（scope）、`active_project?`, `needs_attention?`, `healthy?`
- `ProjectsController#index` は `includes` 済みの配列に対して `select` で上記メソッドを適用しています。

## 動作確認
```bash
bin/rails db:setup
bin/rails db:seed              # サンプル＋大量データを投入
# サーバ起動
bin/rails server
```
- ブラウザで `/projects` にアクセスし、チェックボックスでフィルタを試せます。

## Seedデータ
- スコープ検証用の小さなデータセット（Needs Attention / Healthy / Billable Labelsなど）
- 性能確認用に大量データを生成  
  - デフォルト: プロジェクト1万件、各プロジェクトにタスク2件  
  - 環境変数で調整可能:
    - `SEED_BULK_PROJECTS=20000`
    - `SEED_BULK_TASKS_PER_PROJECT=3`（1〜5で指定）
  - 例: `SEED_BULK_PROJECTS=20000 SEED_BULK_TASKS_PER_PROJECT=3 bin/rails db:seed`

## テスト
```bash
bin/rspec spec/requests/projects_index_spec.rb
```
（Bundlerバージョンが合わない場合は `gem install bundler:2.6.9` で揃えてください）
