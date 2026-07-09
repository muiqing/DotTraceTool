# DotTraceUI.ps1 - dotTrace Performance Analysis Tool Desktop GUI
# Run: powershell -ExecutionPolicy Bypass -File DotTraceUI.ps1
# ============================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Load core modules - robust path resolution
if ($PSScriptRoot) {
    $baseDir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $baseDir = $PWD.Path
}
$scriptRoot = Join-Path $baseDir "Scripts"

if (-not (Test-Path (Join-Path $scriptRoot "Core.ps1"))) {
    [System.Windows.MessageBox]::Show("Cannot find Scripts folder at: $scriptRoot", "Error")
    exit 1
}

. (Join-Path $scriptRoot "Config.ps1")
. (Join-Path $scriptRoot "Core.ps1")

# ============================================
# XAML UI Definition
# ============================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="dotTrace Performance Profiler v1.0" Height="720" Width="1050"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E2E" Foreground="#CDD6F4">
    <Window.Resources>
        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="#1E1E2E"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="12,6"/>
        </Style>
        <Style TargetType="Button" x:Key="PrimaryBtn">
            <Setter Property="Background" Value="#89B4FA"/>
            <Setter Property="Foreground" Value="#1E1E2E"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="Button" x:Key="DangerBtn">
            <Setter Property="Background" Value="#F38BA8"/>
            <Setter Property="Foreground" Value="#1E1E2E"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#BAC2DE"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="ListViewItem">
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Foreground" Value="#1E1E2E"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Padding" Value="8"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="180"/>
        </Grid.RowDefinitions>

        <!-- Top Status Bar -->
        <Border Grid.Row="0" Background="#181825" Padding="12,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <TextBlock Text="Target: " FontSize="13" VerticalAlignment="Center" Margin="0,0,4,0"/>
                    <TextBlock x:Name="txtProcessName" Text="-" FontSize="13" FontWeight="Bold" Foreground="#A6E3A1" VerticalAlignment="Center" Margin="0,0,16,0"/>
                    <TextBlock Text="PID: " FontSize="12" VerticalAlignment="Center" Margin="0,0,4,0"/>
                    <TextBlock x:Name="txtPID" Text="-" FontSize="12" Foreground="#F9E2AF" VerticalAlignment="Center" Margin="0,0,16,0"/>
                    <Ellipse x:Name="statusDot" Width="10" Height="10" Fill="#F38BA8" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <TextBlock x:Name="txtStatus" Text="Disconnected" FontSize="12" VerticalAlignment="Center"/>
                </StackPanel>
                <StackPanel Grid.Column="2" Orientation="Horizontal">
                    <TextBlock Text="dotTrace: " FontSize="11" VerticalAlignment="Center" Margin="0,0,4,0" Foreground="#6C7086"/>
                    <TextBlock x:Name="txtToolStatus" Text="Checking..." FontSize="11" VerticalAlignment="Center" Foreground="#6C7086"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Main Content TabControl -->
        <TabControl Grid.Row="1" Background="#1E1E2E" BorderBrush="#45475A" Margin="8,4,8,4">

            <!-- Tab 1: Dashboard -->
            <TabItem Header="Dashboard">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <UniformGrid Grid.Row="0" Columns="4" Margin="0,0,0,12">
                        <Border Background="#313244" CornerRadius="8" Padding="16,12" Margin="4">
                            <StackPanel>
                                <TextBlock Text="CPU Usage" FontSize="11" Foreground="#6C7086"/>
                                <TextBlock x:Name="txtCPU" Text="- %" FontSize="28" FontWeight="Bold" Foreground="#89B4FA"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#313244" CornerRadius="8" Padding="16,12" Margin="4">
                            <StackPanel>
                                <TextBlock Text="Memory" FontSize="11" Foreground="#6C7086"/>
                                <TextBlock x:Name="txtMemory" Text="- MB" FontSize="28" FontWeight="Bold" Foreground="#A6E3A1"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#313244" CornerRadius="8" Padding="16,12" Margin="4">
                            <StackPanel>
                                <TextBlock Text="Threads" FontSize="11" Foreground="#6C7086"/>
                                <TextBlock x:Name="txtThreads" Text="-" FontSize="28" FontWeight="Bold" Foreground="#F9E2AF"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#313244" CornerRadius="8" Padding="16,12" Margin="4">
                            <StackPanel>
                                <TextBlock Text="Handles" FontSize="11" Foreground="#6C7086"/>
                                <TextBlock x:Name="txtHandles" Text="-" FontSize="28" FontWeight="Bold" Foreground="#F5C2E7"/>
                            </StackPanel>
                        </Border>
                    </UniformGrid>

                    <GroupBox Grid.Row="1" Header="Recent Snapshots">
                        <ListView x:Name="lvSnapshots" Background="#313244" Foreground="#CDD6F4" BorderThickness="0">
                            <ListView.View>
                                <GridView>
                                    <GridViewColumn Header="Filename" Width="360" DisplayMemberBinding="{Binding Name}"/>
                                    <GridViewColumn Header="Size (MB)" Width="100" DisplayMemberBinding="{Binding SizeMB}"/>
                                    <GridViewColumn Header="Time" Width="160" DisplayMemberBinding="{Binding LastWriteTime}"/>
                                </GridView>
                            </ListView.View>
                        </ListView>
                    </GroupBox>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,8,0,0">
                        <Button x:Name="btnManualSnapshot" Content="Manual Snapshot" Style="{StaticResource PrimaryBtn}"/>
                        <Button x:Name="btnRefreshSnapshots" Content="Refresh List" Style="{StaticResource PrimaryBtn}"/>
                        <Button x:Name="btnOpenSnapshotDir" Content="Open Folder" Style="{StaticResource PrimaryBtn}"/>
                        <Button x:Name="btnCleanOld" Content="Clean Old" Style="{StaticResource DangerBtn}"/>
                        <ToggleButton x:Name="btnCrashMonitor" Content="&#x26A0; Crash Monitor: OFF" Padding="16,8" Margin="12,4,4,4" FontSize="13" FontWeight="Bold" Background="#585B70" Foreground="#CDD6F4" BorderThickness="0" Cursor="Hand" Visibility="Collapsed"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <!-- Tab 2: Load Test -->
            <TabItem Header="Load Test">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <GroupBox Grid.Row="0" Header="Configuration">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="150"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="150"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="150"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <Label Grid.Row="0" Grid.Column="0" Content="Test Name:"/>
                            <TextBox x:Name="txtLoadTestName" Grid.Row="0" Grid.Column="1" Text="LoadTest"/>
                            <Label Grid.Row="0" Grid.Column="2" Content="Duration(s):"/>
                            <TextBox x:Name="txtLoadDuration" Grid.Row="0" Grid.Column="3" Text="300"/>
                            <Label Grid.Row="0" Grid.Column="4" Content="Sample Count:"/>
                            <TextBox x:Name="txtLoadSamples" Grid.Row="0" Grid.Column="5" Text="5"/>

                            <Label Grid.Row="1" Grid.Column="0" Content="Each Sample(s):"/>
                            <TextBox x:Name="txtLoadSampleDur" Grid.Row="1" Grid.Column="1" Text="20"/>
                            <Label Grid.Row="1" Grid.Column="2" Content="Profiling Type:"/>
                            <ComboBox x:Name="cmbLoadType" Grid.Row="1" Grid.Column="3" Background="#313244" Foreground="#CDD6F4" SelectedIndex="1">
                                <ComboBoxItem Content="Sampling"/>
                                <ComboBoxItem Content="Timeline"/>
                                <ComboBoxItem Content="Tracing"/>
                            </ComboBox>

                            <StackPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="7" Orientation="Horizontal" Margin="0,12,0,0">
                                <Button x:Name="btnStartLoad" Content="Start Load Test" Style="{StaticResource PrimaryBtn}"/>
                                <Button x:Name="btnStopLoad" Content="Stop" Style="{StaticResource DangerBtn}" IsEnabled="False"/>
                            </StackPanel>
                        </Grid>
                    </GroupBox>

                    <GroupBox Grid.Row="1" Header="Progress">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <ProgressBar x:Name="pbLoad" Grid.Row="0" Height="20" Margin="0,0,0,8" Background="#313244" Foreground="#89B4FA"/>
                            <TextBox x:Name="txtLoadOutput" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap"
                                     VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"/>
                        </Grid>
                    </GroupBox>
                </Grid>
            </TabItem>

            <!-- Tab 3: Scheduled Patrol -->
            <TabItem Header="Patrol">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <GroupBox Grid.Row="0" Header="Patrol Configuration">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="120"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="120"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="120"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <Label Grid.Row="0" Grid.Column="0" Content="Interval(s):"/>
                            <TextBox x:Name="txtPatrolInterval" Grid.Row="0" Grid.Column="1" Text="1800"/>
                            <Label Grid.Row="0" Grid.Column="2" Content="Capture(s):"/>
                            <TextBox x:Name="txtPatrolDuration" Grid.Row="0" Grid.Column="3" Text="15"/>
                            <Label Grid.Row="0" Grid.Column="4" Content="Max Rounds(0=inf):"/>
                            <TextBox x:Name="txtPatrolMaxRounds" Grid.Row="0" Grid.Column="5" Text="0"/>

                            <StackPanel Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="7" Orientation="Horizontal" Margin="0,12,0,0">
                                <Button x:Name="btnStartPatrol" Content="Start Patrol" Style="{StaticResource PrimaryBtn}"/>
                                <Button x:Name="btnStopPatrol" Content="Stop Patrol" Style="{StaticResource DangerBtn}" IsEnabled="False"/>
                                <Button x:Name="btnOpenCSV" Content="View CSV Trend" Style="{StaticResource PrimaryBtn}"/>
                            </StackPanel>
                        </Grid>
                    </GroupBox>

                    <GroupBox Grid.Row="1" Header="Patrol Log">
                        <TextBox x:Name="txtPatrolOutput" IsReadOnly="True" TextWrapping="Wrap"
                                 VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"/>
                    </GroupBox>
                </Grid>
            </TabItem>

            <!-- Tab 4: CPU Trigger -->
            <TabItem Header="CPU Trigger">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <GroupBox Grid.Row="0" Header="Trigger Configuration">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="100"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="100"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="100"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="100"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <Label Grid.Row="0" Grid.Column="0" Content="CPU Threshold(%):"/>
                            <TextBox x:Name="txtCpuThreshold" Grid.Row="0" Grid.Column="1" Text="70"/>
                            <Label Grid.Row="0" Grid.Column="2" Content="Check Interval(s):"/>
                            <TextBox x:Name="txtCpuInterval" Grid.Row="0" Grid.Column="3" Text="5"/>
                            <Label Grid.Row="0" Grid.Column="4" Content="Cooldown(s):"/>
                            <TextBox x:Name="txtCpuCooldown" Grid.Row="0" Grid.Column="5" Text="300"/>
                            <Label Grid.Row="0" Grid.Column="6" Content="Max Captures:"/>
                            <TextBox x:Name="txtCpuMaxCaptures" Grid.Row="0" Grid.Column="7" Text="10"/>

                            <StackPanel Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="9" Orientation="Horizontal" Margin="0,12,0,0">
                                <Button x:Name="btnStartCpuMonitor" Content="Start CPU Monitor" Style="{StaticResource PrimaryBtn}"/>
                                <Button x:Name="btnStopCpuMonitor" Content="Stop Monitor" Style="{StaticResource DangerBtn}" IsEnabled="False"/>
                                <CheckBox x:Name="chkIncludeMemory" Content=" Also monitor memory (trigger when over 2GB)" Foreground="#CDD6F4" VerticalAlignment="Center" Margin="16,0,0,0"/>
                            </StackPanel>
                        </Grid>
                    </GroupBox>

                    <GroupBox Grid.Row="1" Header="Monitor Status">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,8">
                                <TextBlock Text="Current CPU: " Foreground="#6C7086"/>
                                <TextBlock x:Name="txtCpuCurrent" Text="-%" FontWeight="Bold" Foreground="#89B4FA"/>
                                <TextBlock Text="    Triggered: " Foreground="#6C7086" Margin="16,0,0,0"/>
                                <TextBlock x:Name="txtCpuTriggerCount" Text="0" FontWeight="Bold" Foreground="#F9E2AF"/>
                                <TextBlock Text="    Status: " Foreground="#6C7086" Margin="16,0,0,0"/>
                                <TextBlock x:Name="txtCpuMonitorStatus" Text="Not Running" Foreground="#F38BA8"/>
                            </StackPanel>
                            <TextBox x:Name="txtCpuOutput" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap"
                                     VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"/>
                        </Grid>
                    </GroupBox>
                </Grid>
            </TabItem>

            <!-- Tab 5: Automation -->
            <TabItem Header="Automation">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="160"/>
                    </Grid.RowDefinitions>

                    <GroupBox Grid.Row="0" Header="Script Library (Automation\UI\)">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            <ListView x:Name="lvAutoScripts" Grid.Row="0" Background="#313244" Foreground="#CDD6F4" BorderThickness="0">
                                <ListView.View>
                                    <GridView>
                                        <GridViewColumn Header="Sel" Width="40" DisplayMemberBinding="{Binding SelMark}"/>
                                        <GridViewColumn Header="Script Name" Width="300" DisplayMemberBinding="{Binding Name}"/>
                                        <GridViewColumn Header="Snap" Width="50" DisplayMemberBinding="{Binding SnapMark}"/>
                                        <GridViewColumn Header="Status" Width="100" DisplayMemberBinding="{Binding Status}"/>
                                    </GridView>
                                </ListView.View>
                            </ListView>
                            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,8,0,0">
                                <Button x:Name="btnAutoSelectAll" Content="&#x2713; Select All" Style="{StaticResource PrimaryBtn}" Padding="10,6"/>
                                <Button x:Name="btnAutoDeselectAll" Content="&#x2717; Deselect All" Style="{StaticResource PrimaryBtn}" Padding="10,6"/>
                                <Button x:Name="btnAutoToggleSel" Content="Toggle Select" Style="{StaticResource PrimaryBtn}" Padding="10,6"/>
                                <Button x:Name="btnAutoToggleSnap" Content="Toggle Snapshot" Style="{StaticResource PrimaryBtn}" Padding="10,6"/>
                                <Button x:Name="btnAutoRefresh" Content="&#x21BB; Refresh" Style="{StaticResource PrimaryBtn}" Padding="10,6"/>
                                <Button x:Name="btnAutoOpenDir" Content="Open Folder" Style="{StaticResource PrimaryBtn}" Padding="10,6"/>
                            </StackPanel>
                        </Grid>
                    </GroupBox>

                    <GroupBox Grid.Row="1" Header="Execution Control">
                        <StackPanel Orientation="Horizontal">
                            <Label Content="Profiling Type:"/>
                            <ComboBox x:Name="cmbAutoType" Background="#313244" Foreground="#CDD6F4" Width="120" SelectedIndex="0">
                                <ComboBoxItem Content="Sampling"/>
                                <ComboBoxItem Content="Timeline"/>
                                <ComboBoxItem Content="Tracing"/>
                            </ComboBox>
                            <Label Content="Timeout(s):" Margin="16,0,0,0"/>
                            <TextBox x:Name="txtAutoTimeout" Width="60" Text="300"/>
                            <Button x:Name="btnAutoRunSelected" Content="&#x25B6; Run Selected" Style="{StaticResource PrimaryBtn}" Margin="16,0,0,0"/>
                            <Button x:Name="btnAutoRunAllSnap" Content="&#x25B6; Run All + Snapshot" Style="{StaticResource PrimaryBtn}"/>
                            <Button x:Name="btnAutoStop" Content="Stop" Style="{StaticResource DangerBtn}" IsEnabled="False"/>
                        </StackPanel>
                    </GroupBox>

                    <GroupBox Grid.Row="2" Header="Execution Log">
                        <TextBox x:Name="txtAutoLog" IsReadOnly="True" TextWrapping="Wrap"
                                 VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"
                                 Background="#11111B" Foreground="#A6ADC8" BorderThickness="0"/>
                    </GroupBox>
                </Grid>
            </TabItem>

            <!-- Tab 6: Report Analysis -->
            <TabItem Header="Report">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <GroupBox Grid.Row="0" Header="Report Configuration">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <Label Grid.Row="0" Grid.Column="0" Content="Snapshot (.dtp):"/>
                            <TextBox x:Name="txtReportSnapshot" Grid.Row="0" Grid.Column="1"/>
                            <Button x:Name="btnBrowseReportSnapshot" Grid.Row="0" Grid.Column="2" Content="Browse" Style="{StaticResource PrimaryBtn}" Padding="8,4"/>

                            <Label Grid.Row="1" Grid.Column="0" Content="Pattern (.xml):"/>
                            <TextBox x:Name="txtReportPattern" Grid.Row="1" Grid.Column="1"/>
                            <Button x:Name="btnBrowseReportPattern" Grid.Row="1" Grid.Column="2" Content="Browse" Style="{StaticResource PrimaryBtn}" Padding="8,4"/>

                            <Label Grid.Row="2" Grid.Column="0" Content="Output (.xml):"/>
                            <TextBox x:Name="txtReportOutput" Grid.Row="2" Grid.Column="1"/>
                            <Button x:Name="btnBrowseReportOutput" Grid.Row="2" Grid.Column="2" Content="Browse" Style="{StaticResource PrimaryBtn}" Padding="8,4"/>

                            <StackPanel Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,12,0,0">
                                <Button x:Name="btnGenerateReport" Content="Generate Report" Style="{StaticResource PrimaryBtn}"/>
                                <Button x:Name="btnOpenReportOutput" Content="Open Output" Style="{StaticResource PrimaryBtn}"/>
                                <Button x:Name="btnOpenReportDir" Content="Open Folder" Style="{StaticResource PrimaryBtn}"/>
                            </StackPanel>
                        </Grid>
                    </GroupBox>

                    <GroupBox Grid.Row="1" Header="Execution Log">
                        <TextBox x:Name="txtReportLog" IsReadOnly="True" TextWrapping="Wrap"
                                 VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"
                                 Background="#11111B" Foreground="#A6ADC8" BorderThickness="0"/>
                    </GroupBox>
                </Grid>
            </TabItem>

            <!-- Tab 7: Settings -->
            <TabItem Header="Settings">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <GroupBox Grid.Row="0" Header="Basic Settings">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <Label Grid.Row="0" Grid.Column="0" Content="Process Name:"/>
                            <TextBox x:Name="txtSettingAppName" Grid.Row="0" Grid.Column="1"/>

                            <Label Grid.Row="1" Grid.Column="0" Content="App Path:"/>
                            <TextBox x:Name="txtSettingAppPath" Grid.Row="1" Grid.Column="1"/>
                            <Button x:Name="btnBrowseApp" Grid.Row="1" Grid.Column="2" Content="Browse" Style="{StaticResource PrimaryBtn}" Padding="8,4"/>
                        </Grid>
                    </GroupBox>

                    <GroupBox Grid.Row="1" Header="Snapshot Retention">
                        <StackPanel Orientation="Horizontal">
                            <Label Content="Keep Days:"/>
                            <TextBox x:Name="txtSettingMaxAge" Width="60"/>
                            <Label Content="Default Type:" Margin="24,0,0,0"/>
                            <ComboBox x:Name="cmbSettingType" Background="#313244" Foreground="#CDD6F4" Width="120">
                                <ComboBoxItem Content="Sampling"/>
                                <ComboBoxItem Content="Timeline"/>
                                <ComboBoxItem Content="Tracing"/>
                            </ComboBox>
                            <Button x:Name="btnSaveSettings" Content="Save Settings" Style="{StaticResource PrimaryBtn}" Margin="24,0,0,0"/>
                        </StackPanel>
                    </GroupBox>

                    <GroupBox Grid.Row="2" Header="About">
                        <TextBlock TextWrapping="Wrap" Foreground="#6C7086" FontSize="12">
                            <Run Text="dotTrace Performance Profiler v1.0" FontWeight="Bold" Foreground="#CDD6F4"/>
                            <LineBreak/><LineBreak/>
                            <Run Text="Automated performance analysis solution based on JetBrains dotTrace CLI."/>
                            <LineBreak/>
                            <Run Text="Supports: Load Test Profiling, Scheduled Patrol, CPU Auto-Trigger, A/B Compare."/>
                            <LineBreak/><LineBreak/>
                            <Run Text="Sampling: ~2% overhead, suitable for production"/>
                            <LineBreak/>
                            <Run Text="Timeline: ~5% overhead, shows thread concurrency"/>
                            <LineBreak/>
                            <Run Text="Tracing: ~20%+ overhead, dev environment only"/>
                        </TextBlock>
                    </GroupBox>
                </Grid>
            </TabItem>
        </TabControl>

        <!-- Bottom Log Area -->
        <Border Grid.Row="2" Background="#181825" Padding="8">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="Log Output" FontSize="12" Foreground="#6C7086" Margin="0,0,0,4"/>
                <TextBox x:Name="txtGlobalLog" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"
                         Background="#11111B" Foreground="#A6ADC8" BorderThickness="0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ============================================
# Create Window
# ============================================
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get control references
$controls = @{}
$xaml.SelectNodes('//*[@*[contains(translate(name(),"X","x"),"x:Name")]]') | ForEach-Object {
    $name = $_.GetAttribute("x:Name")
    if ($name) { $controls[$name] = $window.FindName($name) }
}

# ============================================
# Helper Functions
# ============================================
function Append-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        "OK"    { "[OK]   " }
        "WARN"  { "[WARN] " }
        "ERROR" { "[ERR]  " }
        default { "[INFO] " }
    }
    $line = $timestamp + " " + $prefix + " " + $Message + "`r`n"
    $controls['txtGlobalLog'].Dispatcher.Invoke([Action]{
        $controls['txtGlobalLog'].AppendText($line)
        $controls['txtGlobalLog'].ScrollToEnd()
    })
    Write-PerfLog $Message $Level | Out-Null
}

function Update-ProcessStatus {
    $proc = Get-TargetProcess
    if ($proc) {
        $controls['txtProcessName'].Text = $Global:DotTraceConfig.AppName + ".exe"
        $controls['txtPID'].Text = $proc.Id.ToString()
        $controls['txtStatus'].Text = "Running"
        $controls['statusDot'].Fill = [System.Windows.Media.Brushes]::LightGreen

        $cpu = Get-CpuUsage
        $mem = [math]::Round($proc.WorkingSet64 / 1MB, 0)
        $controls['txtCPU'].Text = $cpu.ToString() + " %"
        $controls['txtMemory'].Text = $mem.ToString() + " MB"
        $controls['txtThreads'].Text = $proc.Threads.Count.ToString()
        $controls['txtHandles'].Text = $proc.HandleCount.ToString()
    } else {
        $controls['txtProcessName'].Text = $Global:DotTraceConfig.AppName + ".exe"
        $controls['txtPID'].Text = "-"
        $controls['txtStatus'].Text = "Not Running"
        $controls['statusDot'].Fill = [System.Windows.Media.Brushes]::IndianRed
        $controls['txtCPU'].Text = "- %"
        $controls['txtMemory'].Text = "- MB"
        $controls['txtThreads'].Text = "-"
        $controls['txtHandles'].Text = "-"
    }
}

function Refresh-SnapshotList {
    $controls['lvSnapshots'].Items.Clear()
    $snapshots = Get-SnapshotList
    foreach ($s in $snapshots) {
        $controls['lvSnapshots'].Items.Add($s) | Out-Null
    }
}

function Show-FileBrowser {
    param([string]$Filter = "Executable (*.exe)|*.exe|All Files (*.*)|*.*")
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = $Filter
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

# ============================================
# Crash Monitor State
# ============================================
$script:crashMonitorEnabled = $false
$script:lastProcessRunning = $false
$script:crashSessionActive = $false
$script:crashSnapshotInProgress = $false
$script:crashProfilingProcess = $null

function Start-CrashMonitorSession {
    # 守卫：防止重复启动
    if ($script:crashSessionActive) { return }

    $proc = Get-TargetProcess
    if (-not $proc) {
        Append-Log "Crash Monitor: target process not running, waiting..." "WARN"
        $script:lastProcessRunning = $false
        return
    }
    $script:lastProcessRunning = $true

    # 使用 attach --timeout=0 模式：进程退出时 dotTrace 自动保存快照
    $toolPath = $Global:DotTraceConfig.ToolPath
    $snapshotDir = $Global:DotTraceConfig.SnapshotDir
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outFile = Join-Path $snapshotDir ("CrashMonitor_" + $timestamp + ".dtp")
    $script:crashMonitorOutFile = $outFile

    $argList = @(
        "attach",
        $proc.Id.ToString(),
        "--save-to=`"$outFile`"",
        "--profiling-type=Sampling",
        "--timeout=0"
    )

    try {
        $script:crashProfilingProcess = Start-Process -FilePath $toolPath -ArgumentList $argList -WindowStyle Hidden -PassThru
        $script:crashSessionActive = $true
        Append-Log ("Crash Monitor: profiling session started on PID " + $proc.Id.ToString()) "OK"
    } catch {
        Append-Log ("Crash Monitor: failed to start profiling - " + $_.Exception.Message) "ERROR"
        $script:crashSessionActive = $false
    }
}

function Stop-CrashMonitorSession {
    if ($script:crashProfilingProcess -and (-not $script:crashProfilingProcess.HasExited)) {
        try {
            # attach 模式下没有 stop 命令，直接终止 dotTrace 进程
            $script:crashProfilingProcess | Stop-Process -Force
            Append-Log "Crash Monitor: profiling session terminated" "OK"
        } catch {
            Append-Log ("Crash Monitor: failed to stop profiling - " + $_.Exception.Message) "WARN"
        }
    }
    $script:crashSessionActive = $false
    $script:crashProfilingProcess = $null
}

function Invoke-CrashDetected {
    Append-Log "Crash Monitor: *** PROCESS CRASH DETECTED ***" "ERROR"
    $script:crashSnapshotInProgress = $true

    # attach --timeout=0 模式下，目标进程退出后 dotTrace 会自动保存快照并退出
    # 等待 dotTrace 进程完成写入（最多等 15 秒）
    if ($script:crashProfilingProcess -and (-not $script:crashProfilingProcess.HasExited)) {
        Append-Log "Crash Monitor: waiting for dotTrace to finalize snapshot..."
        $waited = $script:crashProfilingProcess.WaitForExit(15000)
        if (-not $waited) {
            Append-Log "Crash Monitor: dotTrace did not exit in time, force killing" "WARN"
            $script:crashProfilingProcess | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }

    # 等待文件系统刷新
    Start-Sleep -Milliseconds 1000

    # 检查快照文件（含重试）
    $snapshotFound = $false
    for ($retry = 0; $retry -lt 3; $retry++) {
        if ($script:crashMonitorOutFile -and (Test-Path $script:crashMonitorOutFile)) {
            $fileSize = [math]::Round((Get-Item $script:crashMonitorOutFile).Length / 1MB, 2)
            if ($fileSize -gt 0) {
                Append-Log ("Crash Monitor: snapshot saved - " + (Split-Path $script:crashMonitorOutFile -Leaf) + " (" + $fileSize.ToString() + " MB)") "OK"
                $snapshotFound = $true
                break
            }
        }
        Start-Sleep -Milliseconds 1000
    }

    if (-not $snapshotFound) {
        Append-Log "Crash Monitor: snapshot file not found or empty, profiling data may be lost" "WARN"
    }

    # Collect crash info from Event Log
    Start-Sleep -Milliseconds 1000
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Id = 1000, 1026
            StartTime = (Get-Date).AddSeconds(-30)
        } -MaxEvents 3 -ErrorAction SilentlyContinue

        if ($events) {
            foreach ($evt in $events) {
                $msgSnippet = $evt.Message.Substring(0, [Math]::Min(150, $evt.Message.Length))
                Append-Log ("  Event[" + $evt.Id.ToString() + "]: " + $msgSnippet) "WARN"
            }
        }
    } catch {
        Append-Log "Crash Monitor: could not read event log" "WARN"
    }

    $script:crashSessionActive = $false
    $script:crashProfilingProcess = $null
    $script:crashSnapshotInProgress = $false

    Refresh-SnapshotList
}

# ============================================
# Event Handlers
# ============================================

# --- Dashboard ---
$controls['btnManualSnapshot'].Add_Click({
    $proc = Get-TargetProcess
    if (-not $proc) {
        Append-Log "Target process not running, cannot capture" "ERROR"
        return
    }
    Append-Log "Starting manual snapshot capture..." "OK"
    $controls['btnManualSnapshot'].IsEnabled = $false

    $snapshot = Start-Snapshot -ProcessId $proc.Id -Label "Manual" -ProfilingType $Global:DotTraceConfig.DefaultType -Duration $Global:DotTraceConfig.DefaultTimeout

    if ($snapshot) {
        $fname = Split-Path $snapshot -Leaf
        Append-Log ("Snapshot saved: " + $fname) "OK"
    } else {
        Append-Log "Snapshot capture failed" "ERROR"
    }
    $controls['btnManualSnapshot'].IsEnabled = $true
    Refresh-SnapshotList
})

$controls['btnCrashMonitor'].Add_Checked({
    $script:crashMonitorEnabled = $true
    $controls['btnCrashMonitor'].Content = [char]0x26A0 + " Crash Monitor: ON"
    $controls['btnCrashMonitor'].Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#F38BA8")
    $controls['btnCrashMonitor'].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#1E1E2E")
    Append-Log "Crash Monitor ENABLED - monitoring for process crash" "OK"

    # Initialize state based on current process status
    $proc = Get-TargetProcess
    if ($proc) {
        $script:lastProcessRunning = $true
        Start-CrashMonitorSession
    } else {
        $script:lastProcessRunning = $false
        Append-Log "Crash Monitor: waiting for target process to start..." "WARN"
    }
})

$controls['btnCrashMonitor'].Add_Unchecked({
    $script:crashMonitorEnabled = $false
    $controls['btnCrashMonitor'].Content = [char]0x26A0 + " Crash Monitor: OFF"
    $controls['btnCrashMonitor'].Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#585B70")
    $controls['btnCrashMonitor'].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#CDD6F4")
    Append-Log "Crash Monitor DISABLED" "WARN"

    Stop-CrashMonitorSession
    $script:lastProcessRunning = $false
})

$controls['btnRefreshSnapshots'].Add_Click({
    Refresh-SnapshotList
    Append-Log "Snapshot list refreshed"
})

$controls['btnOpenSnapshotDir'].Add_Click({
    Start-Process "explorer.exe" -ArgumentList $Global:DotTraceConfig.SnapshotDir
})

$controls['btnCleanOld'].Add_Click({
    $removed = Clear-OldSnapshots
    Append-Log ("Cleaned " + $removed.ToString() + " old snapshots") "OK"
    Refresh-SnapshotList
})

# --- Load Test ---
$controls['btnStartLoad'].Add_Click({
    $proc = Get-TargetProcess
    if (-not $proc) {
        Append-Log "Target process not running, please start app first" "ERROR"
        return
    }

    $testName = $controls['txtLoadTestName'].Text
    $duration = $controls['txtLoadDuration'].Text
    $samples = $controls['txtLoadSamples'].Text
    $sampleDur = $controls['txtLoadSampleDur'].Text
    $typeItem = $controls['cmbLoadType'].SelectedItem
    $type = $typeItem.Content

    $controls['btnStartLoad'].IsEnabled = $false
    $controls['btnStopLoad'].IsEnabled = $true
    $controls['txtLoadOutput'].Text = ""
    $controls['pbLoad'].Maximum = [int]$samples
    $controls['pbLoad'].Value = 0

    Append-Log ("Load test started: " + $testName + ", " + $duration + "s, " + $samples + " samples") "OK"

    $scriptPath = Join-Path $scriptRoot "Profile-UnderLoad.ps1"
    $argString = "-TestDuration " + $duration + " -SampleCount " + $samples + " -SampleDuration " + $sampleDur + " -ProfilingType " + $type + " -TestName " + $testName

    $controls['txtLoadOutput'].AppendText("Executing load test profiling...`r`n")
    $controls['txtLoadOutput'].AppendText("Args: " + $argString + "`r`n`r`n")

    Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"" + $scriptPath + "`" " + $argString) -WindowStyle Normal

    $controls['btnStartLoad'].IsEnabled = $true
    $controls['btnStopLoad'].IsEnabled = $false
})

# --- Scheduled Patrol ---
$controls['btnStartPatrol'].Add_Click({
    $interval = $controls['txtPatrolInterval'].Text
    $duration = $controls['txtPatrolDuration'].Text
    $maxRounds = $controls['txtPatrolMaxRounds'].Text

    $scriptPath = Join-Path $scriptRoot "Scheduled-Patrol.ps1"
    $argString = "-IntervalSeconds " + $interval + " -Duration " + $duration + " -MaxRounds " + $maxRounds

    Append-Log ("Starting patrol: interval=" + $interval + "s, duration=" + $duration + "s") "OK"
    $controls['txtPatrolOutput'].Text = "Patrol started in separate window...`r`n"
    $controls['btnStartPatrol'].IsEnabled = $false
    $controls['btnStopPatrol'].IsEnabled = $true

    Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"" + $scriptPath + "`" " + $argString) -WindowStyle Normal
})

$controls['btnStopPatrol'].Add_Click({
    Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
        try { $_.MainWindowTitle -like "*Scheduled-Patrol*" } catch { $false }
    } | Stop-Process -Force -ErrorAction SilentlyContinue

    $controls['btnStartPatrol'].IsEnabled = $true
    $controls['btnStopPatrol'].IsEnabled = $false
    Append-Log "Patrol stopped" "WARN"
    $controls['txtPatrolOutput'].AppendText("Patrol stopped`r`n")
})

$controls['btnOpenCSV'].Add_Click({
    $csvPath = Join-Path $Global:DotTraceConfig.ReportDir ("patrol_" + (Get-Date -Format "yyyyMMdd") + ".csv")
    if (Test-Path $csvPath) {
        Start-Process $csvPath
    } else {
        Append-Log "No patrol CSV found for today" "WARN"
    }
})

# --- CPU Trigger ---
$controls['btnStartCpuMonitor'].Add_Click({
    $threshold = $controls['txtCpuThreshold'].Text
    $interval = $controls['txtCpuInterval'].Text
    $cooldown = $controls['txtCpuCooldown'].Text
    $maxCaptures = $controls['txtCpuMaxCaptures'].Text
    $includeMem = ""
    if ($controls['chkIncludeMemory'].IsChecked) { $includeMem = " -IncludeMemory" }

    $scriptPath = Join-Path $scriptRoot "Auto-Trigger-CPU.ps1"
    $argString = "-Threshold " + $threshold + " -CheckInterval " + $interval + " -Cooldown " + $cooldown + " -MaxCaptures " + $maxCaptures + $includeMem

    Append-Log ("Starting CPU monitor: threshold=" + $threshold + "%, interval=" + $interval + "s") "OK"
    $controls['txtCpuOutput'].Text = "CPU monitor started...`r`n"
    $controls['txtCpuMonitorStatus'].Text = "Running"
    $controls['txtCpuMonitorStatus'].Foreground = [System.Windows.Media.Brushes]::LightGreen
    $controls['btnStartCpuMonitor'].IsEnabled = $false
    $controls['btnStopCpuMonitor'].IsEnabled = $true

    Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"" + $scriptPath + "`" " + $argString) -WindowStyle Normal
})

$controls['btnStopCpuMonitor'].Add_Click({
    Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
        try { $_.MainWindowTitle -like "*Auto-Trigger*" } catch { $false }
    } | Stop-Process -Force -ErrorAction SilentlyContinue

    $controls['btnStartCpuMonitor'].IsEnabled = $true
    $controls['btnStopCpuMonitor'].IsEnabled = $false
    $controls['txtCpuMonitorStatus'].Text = "Stopped"
    $controls['txtCpuMonitorStatus'].Foreground = [System.Windows.Media.Brushes]::IndianRed
    Append-Log "CPU monitor stopped" "WARN"
})

# --- Report Analysis ---
function Append-ReportLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message`r`n"
    $controls['txtReportLog'].AppendText($line)
    $controls['txtReportLog'].ScrollToEnd()
}

# Set default Report paths from config
$controls['txtReportPattern'].Text = Join-Path $Global:DotTraceConfig.ReportDir "pattern.xml"
$controls['txtReportOutput'].Text = Join-Path $Global:DotTraceConfig.ReportDir ("report_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".xml")

$controls['btnBrowseReportSnapshot'].Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "dotTrace Snapshot|*.dtp|All Files|*.*"
    $dlg.Title = "Select Snapshot File"
    $dlg.InitialDirectory = $Global:DotTraceConfig.SnapshotDir
    if ($dlg.ShowDialog()) { $controls['txtReportSnapshot'].Text = $dlg.FileName }
})

$controls['btnBrowseReportPattern'].Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "XML Pattern|*.xml|All Files|*.*"
    $dlg.Title = "Select Pattern File"
    $dlg.InitialDirectory = $Global:DotTraceConfig.ReportDir
    if ($dlg.ShowDialog()) { $controls['txtReportPattern'].Text = $dlg.FileName }
})

$controls['btnBrowseReportOutput'].Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "XML Report|*.xml|All Files|*.*"
    $dlg.Title = "Save Report As"
    $dlg.InitialDirectory = $Global:DotTraceConfig.ReportDir
    $dlg.FileName = "report_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".xml"
    if ($dlg.ShowDialog()) { $controls['txtReportOutput'].Text = $dlg.FileName }
})

$controls['btnGenerateReport'].Add_Click({
    $reporter = $Global:DotTraceConfig.ReporterPath
    $snapshot = $controls['txtReportSnapshot'].Text
    $pattern = $controls['txtReportPattern'].Text
    $output = $controls['txtReportOutput'].Text

    # Validation
    if (-not $reporter -or -not (Test-Path $reporter)) {
        Append-ReportLog "Reporter.exe not found: $reporter" "ERROR"
        return
    }
    if (-not $snapshot -or -not (Test-Path $snapshot)) {
        Append-ReportLog "Snapshot file not found: $snapshot" "ERROR"
        return
    }
    if (-not $pattern -or -not (Test-Path $pattern)) {
        Append-ReportLog "Pattern file not found: $pattern" "ERROR"
        return
    }
    if (-not $output) {
        Append-ReportLog "Output path is empty" "ERROR"
        return
    }

    # Ensure output directory exists
    $outputDir = Split-Path -Parent $output
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }

    # Build command
    $cmdArgs = @(
        "report",
        "`"$snapshot`"",
        "--pattern=`"$pattern`"",
        "--save-to=`"$output`""
    )

    $cmdDisplay = "`"$reporter`" " + ($cmdArgs -join " ")
    Append-ReportLog "Executing: $cmdDisplay"
    Append-ReportLog "Generating report, please wait..."

    try {
        $result = & $reporter @cmdArgs 2>&1
        $exitCode = $LASTEXITCODE
        $resultText = $result | Out-String

        if ($resultText) {
            Append-ReportLog $resultText.Trim()
        }

        if ($exitCode -eq 0 -and (Test-Path $output)) {
            $size = [math]::Round((Get-Item $output).Length / 1KB, 1)
            Append-ReportLog "Report generated successfully: $output ($size KB)" "OK"
            Append-Log "Report generated: $output" "OK"
        } else {
            Append-ReportLog "Report generation failed (exit code: $exitCode)" "ERROR"
        }
    } catch {
        Append-ReportLog "Exception: $_" "ERROR"
    }
})

$controls['btnOpenReportOutput'].Add_Click({
    $output = $controls['txtReportOutput'].Text
    if ($output -and (Test-Path $output)) {
        Start-Process $output
    } else {
        Append-ReportLog "Output file not found" "WARN"
    }
})

$controls['btnOpenReportDir'].Add_Click({
    $output = $controls['txtReportOutput'].Text
    $dir = if ($output) { Split-Path -Parent $output } else { $Global:DotTraceConfig.ReportDir }
    if (Test-Path $dir) {
        Start-Process explorer.exe $dir
    }
})

# --- Automation (Async Queue + Timer) ---
$script:autoScripts = @()
$script:autoRunning = $false
$script:autoPythonProcess = $null
$script:autoQueue = [System.Collections.Generic.Queue[PSCustomObject]]::new()
$script:autoCurrentItem = $null
$script:autoForceSnapshot = $false
$script:autoProfilingStarted = $false
$script:autoOutFile = ""
$script:autoStartTime = $null
$script:autoProfType = "Sampling"
$script:autoTimeout = 300

$autoDir = Join-Path $baseDir "Automation\UI"

# Async check timer (500ms interval, checks if Python process exited)
$script:autoCheckTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:autoCheckTimer.Interval = [TimeSpan]::FromMilliseconds(500)

function Append-AutoLog {
    param([string]$Message, [string]$Level = "OK")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        "OK"    { "[OK]   " }
        "WARN"  { "[WARN] " }
        "ERROR" { "[ERR]  " }
        default { "[INFO] " }
    }
    $line = $timestamp + " " + $prefix + " " + $Message + "`r`n"
    $controls['txtAutoLog'].Dispatcher.Invoke([Action]{
        $controls['txtAutoLog'].AppendText($line)
        $controls['txtAutoLog'].ScrollToEnd()
    })
}

function Scan-AutomationScripts {
    $script:autoScripts = @()
    if (-not (Test-Path $autoDir)) {
        New-Item -ItemType Directory -Path $autoDir -Force | Out-Null
    }
    $files = Get-ChildItem -Path $autoDir -Filter "*.py" -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $script:autoScripts += [PSCustomObject]@{
            Name     = $f.Name
            Path     = $f.FullName
            Selected = $true
            Snapshot = $false
            Status   = "Ready"
            SelMark  = [char]0x2713
            SnapMark = "-"
        }
    }
}

function Refresh-AutoScriptList {
    Scan-AutomationScripts
    $controls['lvAutoScripts'].Items.Clear()
    foreach ($s in $script:autoScripts) {
        $controls['lvAutoScripts'].Items.Add($s) | Out-Null
    }
    $count = @($script:autoScripts).Count
    Append-AutoLog ("Found " + $count.ToString() + " script(s) in Automation\UI\")
}

function Update-AutoListView {
    $controls['lvAutoScripts'].Items.Clear()
    foreach ($s in $script:autoScripts) {
        $s.SelMark = if ($s.Selected) { [char]0x2713 } else { "-" }
        $s.SnapMark = if ($s.Snapshot) { [char]0x2713 } else { "-" }
        $controls['lvAutoScripts'].Items.Add($s) | Out-Null
    }
}

function Start-NextAutoScript {
    # Check if queue is empty
    if ($script:autoQueue.Count -eq 0) {
        # All done
        $script:autoCheckTimer.Stop()
        $script:autoRunning = $false
        $script:autoCurrentItem = $null
        $controls['btnAutoRunSelected'].IsEnabled = $true
        $controls['btnAutoRunAllSnap'].IsEnabled = $true
        $controls['btnAutoStop'].IsEnabled = $false
        Append-AutoLog "Batch execution completed"
        Refresh-SnapshotList
        return
    }

    # Dequeue next item
    $script:autoCurrentItem = $script:autoQueue.Dequeue()
    $item = $script:autoCurrentItem
    $doSnapshot = $script:autoForceSnapshot -or $item.Snapshot

    $item.Status = "Running"
    Update-AutoListView

    Append-AutoLog ("Starting: " + $item.Name + " (Snapshot: " + $(if($doSnapshot){"ON"}else{"OFF"}) + ")")

    $script:autoProfilingStarted = $false
    $script:autoOutFile = ""

    # Start profiling if snapshot enabled
    if ($doSnapshot) {
        $targetProc = Get-TargetProcess
        if ($targetProc) {
            $toolPath = $Global:DotTraceConfig.ToolPath
            $snapshotDir = $Global:DotTraceConfig.SnapshotDir
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $scriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
            $script:autoOutFile = Join-Path $snapshotDir ("Auto_" + $scriptBaseName + "_" + $script:autoProfType + "_" + $timestamp + ".dtp")

            $argList = "start --profiling-type=" + $script:autoProfType + " --save-to=`"" + $script:autoOutFile + "`" --pid=" + $targetProc.Id.ToString()
            try {
                Start-Process -FilePath $toolPath -ArgumentList $argList -WindowStyle Hidden -Wait
                $script:autoProfilingStarted = $true
                Append-AutoLog ("Profiling started on PID " + $targetProc.Id.ToString())
            } catch {
                Append-AutoLog ("Failed to start profiling: " + $_.Exception.Message) "ERROR"
            }
        } else {
            Append-AutoLog "Target process not running, skipping snapshot" "WARN"
        }
    }

    # Launch Python script (non-blocking)
    $script:autoStartTime = Get-Date
    try {
        $script:autoPythonProcess = Start-Process -FilePath "python" -ArgumentList ("`"" + $item.Path + "`"") -WorkingDirectory $autoDir -WindowStyle Normal -PassThru
        # Start the timer to poll for completion
        $script:autoCheckTimer.Start()
    } catch {
        $item.Status = "Failed"
        Append-AutoLog ($item.Name + " launch error: " + $_.Exception.Message) "ERROR"
        Complete-CurrentAutoScript -ForceFail $true
    }
}

function Complete-CurrentAutoScript {
    param([bool]$ForceFail = $false)

    $script:autoCheckTimer.Stop()
    $item = $script:autoCurrentItem

    if (-not $ForceFail -and $script:autoPythonProcess) {
        $elapsed = [math]::Round(((Get-Date) - $script:autoStartTime).TotalSeconds, 1)
        if ($script:autoPythonProcess.ExitCode -eq 0) {
            $item.Status = "Done"
            Append-AutoLog ($item.Name + " completed (" + $elapsed.ToString() + "s)") "OK"
        } else {
            $item.Status = "Failed"
            Append-AutoLog ($item.Name + " failed with exit code " + $script:autoPythonProcess.ExitCode.ToString()) "ERROR"
        }
    }

    # Stop profiling if started
    if ($script:autoProfilingStarted) {
        $toolPath = $Global:DotTraceConfig.ToolPath
        try {
            Start-Process -FilePath $toolPath -ArgumentList "stop" -WindowStyle Hidden -Wait
            Append-AutoLog ("Snapshot saved: " + (Split-Path $script:autoOutFile -Leaf)) "OK"
        } catch {
            Append-AutoLog "Failed to stop profiling" "ERROR"
        }
    }

    $script:autoPythonProcess = $null
    $script:autoProfilingStarted = $false
    Update-AutoListView

    # Start next script in queue
    Start-NextAutoScript
}

# Timer tick handler: check if current Python process has exited
$script:autoCheckTimer.Add_Tick({
    if (-not $script:autoPythonProcess) {
        $script:autoCheckTimer.Stop()
        return
    }

    # Check timeout
    $elapsedSec = ((Get-Date) - $script:autoStartTime).TotalSeconds
    if ($elapsedSec -gt $script:autoTimeout) {
        $script:autoPythonProcess | Stop-Process -Force -ErrorAction SilentlyContinue
        $script:autoCurrentItem.Status = "Timeout"
        Append-AutoLog ($script:autoCurrentItem.Name + " TIMEOUT after " + $script:autoTimeout.ToString() + "s") "ERROR"
        $script:autoPythonProcess = $null
        $script:autoCheckTimer.Stop()

        # Stop profiling if started
        if ($script:autoProfilingStarted) {
            $toolPath = $Global:DotTraceConfig.ToolPath
            try {
                Start-Process -FilePath $toolPath -ArgumentList "stop" -WindowStyle Hidden -Wait
                Append-AutoLog ("Snapshot saved: " + (Split-Path $script:autoOutFile -Leaf)) "OK"
            } catch {
                Append-AutoLog "Failed to stop profiling" "ERROR"
            }
            $script:autoProfilingStarted = $false
        }

        Update-AutoListView
        Start-NextAutoScript
        return
    }

    # Check if process exited
    if ($script:autoPythonProcess.HasExited) {
        Complete-CurrentAutoScript
    }
})

$controls['btnAutoRefresh'].Add_Click({
    Refresh-AutoScriptList
})

$controls['btnAutoOpenDir'].Add_Click({
    if (-not (Test-Path $autoDir)) { New-Item -ItemType Directory -Path $autoDir -Force | Out-Null }
    Start-Process "explorer.exe" -ArgumentList $autoDir
})

$controls['btnAutoSelectAll'].Add_Click({
    foreach ($item in $script:autoScripts) { $item.Selected = $true }
    Update-AutoListView
})

$controls['btnAutoDeselectAll'].Add_Click({
    foreach ($item in $script:autoScripts) { $item.Selected = $false }
    Update-AutoListView
})

$controls['btnAutoToggleSel'].Add_Click({
    $idx = $controls['lvAutoScripts'].SelectedIndex
    if ($idx -ge 0 -and $idx -lt $script:autoScripts.Count) {
        $script:autoScripts[$idx].Selected = -not $script:autoScripts[$idx].Selected
        Update-AutoListView
        $controls['lvAutoScripts'].SelectedIndex = $idx
    } else {
        Append-AutoLog "Please select a script row first" "WARN"
    }
})

$controls['btnAutoToggleSnap'].Add_Click({
    $idx = $controls['lvAutoScripts'].SelectedIndex
    if ($idx -ge 0 -and $idx -lt $script:autoScripts.Count) {
        $script:autoScripts[$idx].Snapshot = -not $script:autoScripts[$idx].Snapshot
        Update-AutoListView
        $controls['lvAutoScripts'].SelectedIndex = $idx
    } else {
        Append-AutoLog "Please select a script row first" "WARN"
    }
})

$controls['btnAutoRunSelected'].Add_Click({
    if ($script:autoRunning) { return }
    $selected = @($script:autoScripts | Where-Object { $_.Selected })
    if ($selected.Count -eq 0) {
        Append-AutoLog "No scripts selected" "WARN"
        return
    }

    $script:autoRunning = $true
    $script:autoForceSnapshot = $false
    $controls['btnAutoRunSelected'].IsEnabled = $false
    $controls['btnAutoRunAllSnap'].IsEnabled = $false
    $controls['btnAutoStop'].IsEnabled = $true
    $controls['txtAutoLog'].Text = ""

    $typeItem = $controls['cmbAutoType'].SelectedItem
    $script:autoProfType = $typeItem.Content
    $script:autoTimeout = [int]$controls['txtAutoTimeout'].Text

    Append-AutoLog ("Batch execution started: " + $selected.Count.ToString() + " script(s), Type=" + $script:autoProfType)

    # Fill queue
    $script:autoQueue.Clear()
    foreach ($item in $selected) {
        $script:autoQueue.Enqueue($item)
    }

    # Start first script (non-blocking)
    Start-NextAutoScript
})

$controls['btnAutoRunAllSnap'].Add_Click({
    if ($script:autoRunning) { return }

    $script:autoRunning = $true
    $script:autoForceSnapshot = $true
    $controls['btnAutoRunSelected'].IsEnabled = $false
    $controls['btnAutoRunAllSnap'].IsEnabled = $false
    $controls['btnAutoStop'].IsEnabled = $true
    $controls['txtAutoLog'].Text = ""

    $typeItem = $controls['cmbAutoType'].SelectedItem
    $script:autoProfType = $typeItem.Content
    $script:autoTimeout = [int]$controls['txtAutoTimeout'].Text

    Append-AutoLog ("Run All + Snapshot: " + @($script:autoScripts).Count.ToString() + " script(s), Type=" + $script:autoProfType)

    # Fill queue with all scripts
    $script:autoQueue.Clear()
    foreach ($item in $script:autoScripts) {
        $script:autoQueue.Enqueue($item)
    }

    # Start first script (non-blocking)
    Start-NextAutoScript
})

$controls['btnAutoStop'].Add_Click({
    # Stop timer immediately
    $script:autoCheckTimer.Stop()

    # Kill current Python process
    if ($script:autoPythonProcess -and (-not $script:autoPythonProcess.HasExited)) {
        $script:autoPythonProcess | Stop-Process -Force -ErrorAction SilentlyContinue
        Append-AutoLog "Current script killed" "WARN"
    }

    # Stop profiling if active
    if ($script:autoProfilingStarted) {
        $toolPath = $Global:DotTraceConfig.ToolPath
        try {
            Start-Process -FilePath $toolPath -ArgumentList "stop" -WindowStyle Hidden -Wait
            Append-AutoLog ("Snapshot saved: " + (Split-Path $script:autoOutFile -Leaf)) "OK"
        } catch {
            Append-AutoLog "Failed to stop profiling" "ERROR"
        }
        $script:autoProfilingStarted = $false
    }

    # Clear queue and reset state
    $script:autoQueue.Clear()
    $script:autoRunning = $false
    $script:autoPythonProcess = $null
    $script:autoCurrentItem = $null

    $controls['btnAutoRunSelected'].IsEnabled = $true
    $controls['btnAutoRunAllSnap'].IsEnabled = $true
    $controls['btnAutoStop'].IsEnabled = $false
    Append-AutoLog "Execution stopped" "WARN"
    Update-AutoListView
})

# --- Settings ---
$controls['btnBrowseApp'].Add_Click({
    $path = Show-FileBrowser
    if ($path) { $controls['txtSettingAppPath'].Text = $path }
})

$controls['btnSaveSettings'].Add_Click({
    $Global:DotTraceConfig.AppName = $controls['txtSettingAppName'].Text
    $Global:DotTraceConfig.AppPath = $controls['txtSettingAppPath'].Text
    $Global:DotTraceConfig.MaxSnapshotAge = [int]$controls['txtSettingMaxAge'].Text
    $typeItem = $controls['cmbSettingType'].SelectedItem
    $Global:DotTraceConfig.DefaultType = $typeItem.Content

    # 重写 Config.ps1 文件，使设置持久化
    $configPath = Join-Path $scriptRoot "Config.ps1"
    $configContent = @"
# Config.ps1 - 全局配置
# ============================================
# 使用前请根据实际环境修改以下配置

# 基于脚本目录解析项目根目录
`$_configScriptRoot = if (`$PSScriptRoot) { `$PSScriptRoot } else { Split-Path -Parent `$MyInvocation.MyCommand.Path }
`$_projectRoot = Split-Path -Parent `$_configScriptRoot

`$Global:DotTraceConfig = @{
    # dotTrace 工具路径（相对于项目根目录，自动解析，无需手动配置）
    ToolPath       = (Join-Path `$_projectRoot "JetBrains.dotTrace\dottrace.exe")
    ReporterPath   = (Join-Path `$_projectRoot "JetBrains.dotTrace\Reporter.exe")

    # 目标应用（修改为你的桌面软件名称，不含 .exe）
    AppName        = "$($Global:DotTraceConfig.AppName)"
    AppPath        = "$($Global:DotTraceConfig.AppPath)"

    # 输出目录（相对于项目根目录）
    OutputRoot     = `$_projectRoot
    SnapshotDir    = (Join-Path `$_projectRoot "Snapshots")
    ReportDir      = (Join-Path `$_projectRoot "Reports")
    LogDir         = (Join-Path `$_projectRoot "Logs")

    # 分析参数
    DefaultType    = "$($Global:DotTraceConfig.DefaultType)"
    DefaultTimeout = 30

    # CPU 触发阈值
    CpuThreshold      = 70
    CpuCheckInterval  = 5
    CpuCooldown       = 300

    # 定时巡检
    PatrolInterval = 1800
    PatrolDuration = 15

    # 快照保留策略
    MaxSnapshotAge  = $($Global:DotTraceConfig.MaxSnapshotAge)
    MaxSnapshotSize = 5GB
    MaxCaptures     = 10
}

# 确保目录存在
`$dirsToCreate = @(`$Global:DotTraceConfig.SnapshotDir, `$Global:DotTraceConfig.ReportDir, `$Global:DotTraceConfig.LogDir)
foreach (`$d in `$dirsToCreate) {
    if (`$d -and -not (Test-Path `$d)) {
        New-Item -ItemType Directory -Force -Path `$d | Out-Null
    }
}
"@
    try {
        [System.IO.File]::WriteAllText($configPath, $configContent, [System.Text.Encoding]::UTF8)
        Append-Log "Settings saved to Config.ps1" "OK"
    } catch {
        Append-Log ("Failed to save Config.ps1: " + $_.Exception.Message) "ERROR"
    }
    Update-ProcessStatus
})

# ============================================
# Initialization
# ============================================

# Load settings into UI
$controls['txtSettingAppName'].Text = $Global:DotTraceConfig.AppName
$controls['txtSettingAppPath'].Text = $Global:DotTraceConfig.AppPath
$controls['txtSettingMaxAge'].Text = $Global:DotTraceConfig.MaxSnapshotAge.ToString()

# Set default profiling type
$typeIndex = switch ($Global:DotTraceConfig.DefaultType) {
    "Sampling" { 0 }
    "Timeline" { 1 }
    "Tracing"  { 2 }
    default    { 0 }
}
$controls['cmbSettingType'].SelectedIndex = $typeIndex

# Check dotTrace availability
if (Test-Path $Global:DotTraceConfig.ToolPath) {
    $controls['txtToolStatus'].Text = "Installed"
    $controls['txtToolStatus'].Foreground = [System.Windows.Media.Brushes]::LightGreen
} else {
    $controls['txtToolStatus'].Text = "Not Found"
    $controls['txtToolStatus'].Foreground = [System.Windows.Media.Brushes]::IndianRed
}

# Defer initial status update to after window is rendered
$window.Add_Loaded({
    Update-ProcessStatus
    Refresh-SnapshotList
    Refresh-AutoScriptList
    Append-Log "dotTrace Performance Profiler started" "OK"
    Append-Log ("Target: " + $Global:DotTraceConfig.AppName + " | Tool: " + $Global:DotTraceConfig.ToolPath)
})

# Timer for periodic status refresh (every 3 seconds)
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(3)
$timer.Add_Tick({
    Update-ProcessStatus

    # Crash Monitor logic
    if ($script:crashMonitorEnabled -and (-not $script:crashSnapshotInProgress)) {
        $proc = Get-TargetProcess
        $currentlyRunning = ($null -ne $proc)

        if ($script:lastProcessRunning -and (-not $currentlyRunning)) {
            # Transition: Running -> Not Running = CRASH
            Invoke-CrashDetected
        }
        elseif ((-not $script:lastProcessRunning) -and $currentlyRunning) {
            # Transition: Not Running -> Running = process started/restarted
            Append-Log "Crash Monitor: target process detected, starting profiling session" "OK"
            Start-CrashMonitorSession
        }
        elseif ($currentlyRunning -and (-not $script:crashSessionActive)) {
            # Process running but no active session (e.g. session died)
            Start-CrashMonitorSession
        }

        $script:lastProcessRunning = $currentlyRunning
    }
})
$timer.Start()

# ============================================
# Show Window
# ============================================
$window.ShowDialog() | Out-Null
$timer.Stop()
$script:autoCheckTimer.Stop()
