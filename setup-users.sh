## === MODULE 02: User Creation ===
echo "👤 Creating users: ubuntu, moneill, matt..."
for user in ubuntu moneill matt; do
  if ! id "$user" &>/dev/null; then
    adduser --disabled-password --gecos "" "$user"
    usermod -aG sudo "$user"
    echo "✅ Created user: $user"
  else
    usermod -aG sudo "$user" || true
    echo "⚠️ User $user already exists; ensured sudo membership."
  fi

  # SSH keys: reuse root's authorized_keys if present
  if [ -f /root/.ssh/authorized_keys ]; then
    mkdir -p /home/$user/.ssh
    cp /root/.ssh/authorized_keys /home/$user/.ssh/authorized_keys
    chown -R $user:$user /home/$user/.ssh
    chmod 700 /home/$user/.ssh
    chmod 600 /home/$user/.ssh/authorized_keys
  fi

  # Passwordless sudo for non-interactive setup
  sudo_file="/etc/sudoers.d/90-${user}-nopasswd"
  if [ ! -f "$sudo_file" ]; then
    echo "${user} ALL=(ALL) NOPASSWD:ALL" > "$sudo_file"
    chmod 440 "$sudo_file"
  fi
done
