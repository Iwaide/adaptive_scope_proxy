# Adaptive Scope Proxy

## 使い方

### `link_scope_predicate`
- `scope :active` のような DB スコープと対応する `active?` を `link_scope_predicate :active` で結び付けると、preload 済み association では Ruby 側 predicate だけで絞り込みを完結させます。
- その結果、`user.projects.active` が追加クエリを発行せず、`Project.active` だけは従来どおり DB スコープとして動きます。

```ruby
class Project < ApplicationRecord
  include AdaptiveScopeProxy
  scope :active, -> { where(archived_at: nil) }

  def active?
    archived_at.nil?
  end

  link_scope_predicate :active
end

user = User.preload(:projects).find(1)
user.projects.active.each { |project| puts project.active? }
```

### `link_scope_filter`
- `link_scope_filter :latest_by_user, filter: :latest_by_user_filter` のように records を受け取って走査するクラスメソッドと scope を結び付けると、loaded? なら Ruby 側 filter、未ロードなら DB 側 scope を自動で選択できます。

```ruby
class Project < ApplicationRecord
  include AdaptiveScopeProxy
  scope :latest_by_user, -> { ... }

  def self.latest_by_user_filter(records)
    records.sort_by { [ it.user_id, -it.due_on.to_i ] }.uniq { |rec| rec.user_id }
  end

  link_scope_filter :latest_by_user, filter: :latest_by_user_filter
end

user = User.preload(:projects).find(1)
user.projects.latest_by_user.each { ... }
```

## テスト
- 挙動は `spec/models/concerns/adaptive_scope_proxy.rb` の RSpec で確認できます。

```bash
bundle exec rspec spec/models/concerns/adaptive_scope_proxy.rb
```
