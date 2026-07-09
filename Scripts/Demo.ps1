Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="员工管理系统" Height="500" Width="700"
        WindowStartupLocation="CenterScreen" FontSize="13">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="80"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="80"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- 输入区域 -->
        <TextBlock Text="姓名:" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center" Margin="5"/>
        <TextBox Name="txtName" Grid.Row="0" Grid.Column="1" Margin="5"/>

        <TextBlock Text="年龄:" Grid.Row="0" Grid.Column="2" VerticalAlignment="Center" Margin="5"/>
        <TextBox Name="txtAge" Grid.Row="0" Grid.Column="3" Margin="5"/>

        <TextBlock Text="部门:" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center" Margin="5"/>
        <ComboBox Name="cmbDept" Grid.Row="1" Grid.Column="1" Margin="5" SelectedIndex="0">
            <ComboBoxItem Content="技术部"/>
            <ComboBoxItem Content="市场部"/>
            <ComboBoxItem Content="人事部"/>
            <ComboBoxItem Content="财务部"/>
        </ComboBox>

        <TextBlock Text="职位:" Grid.Row="1" Grid.Column="2" VerticalAlignment="Center" Margin="5"/>
        <TextBox Name="txtPosition" Grid.Row="1" Grid.Column="3" Margin="5"/>

        <!-- 按钮区 -->
        <StackPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="4" 
                    Orientation="Horizontal" HorizontalAlignment="Center" Margin="5,10">
            <Button Name="btnAdd" Content="添加" Width="80" Margin="5"/>
            <Button Name="btnDelete" Content="删除" Width="80" Margin="5"/>
            <Button Name="btnClear" Content="清空输入" Width="80" Margin="5"/>
            <Button Name="btnExport" Content="导出CSV" Width="80" Margin="5"/>
        </StackPanel>

        <!-- 搜索 -->
        <StackPanel Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="4" 
                    Orientation="Horizontal" Margin="5">
            <TextBlock Text="搜索:" VerticalAlignment="Center" Margin="5"/>
            <TextBox Name="txtSearch" Width="200" Margin="5"/>
            <Button Name="btnSearch" Content="查找" Width="60" Margin="5"/>
        </StackPanel>

        <!-- 数据表格 -->
        <DataGrid Name="dgEmployees" Grid.Row="4" Grid.Column="0" Grid.ColumnSpan="4"
                  AutoGenerateColumns="False" IsReadOnly="True" CanUserAddRows="False" Margin="5">
            <DataGrid.Columns>
                <DataGridTextColumn Header="姓名" Binding="{Binding Name}" Width="100"/>
                <DataGridTextColumn Header="年龄" Binding="{Binding Age}" Width="60"/>
                <DataGridTextColumn Header="部门" Binding="{Binding Dept}" Width="100"/>
                <DataGridTextColumn Header="职位" Binding="{Binding Position}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>

        <!-- 状态栏 -->
        <TextBlock Name="lblStatus" Grid.Row="5" Grid.Column="0" Grid.ColumnSpan="4" 
                   Margin="5" Foreground="Gray"/>
    </Grid>
</Window>
"@

# 解析窗口
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# 获取所有控件
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $window.FindName($_.Name)
}

# 数据存储
$script:employees = [System.Collections.ArrayList]::new()

# 更新状态栏
function Update-Status {
    $lblStatus.Text = "共 $($script:employees.Count) 条记录"
}

# 添加员工
$btnAdd.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtName.Text)) {
        [System.Windows.MessageBox]::Show("请输入姓名", "提示")
        return
    }

    $emp = [PSCustomObject]@{
        Name     = $txtName.Text
        Age      = $txtAge.Text
        Dept     = $cmbDept.SelectedItem.Content
        Position = $txtPosition.Text
    }

    $script:employees.Add($emp) | Out-Null
    $dgEmployees.ItemsSource = $null
    $dgEmployees.ItemsSource = $script:employees
    Update-Status
})

# 删除选中
$btnDelete.Add_Click({
    $selected = $dgEmployees.SelectedItem
    if ($selected) {
        $script:employees.Remove($selected)
        $dgEmployees.ItemsSource = $null
        $dgEmployees.ItemsSource = $script:employees
        Update-Status
    }
})

# 清空输入
$btnClear.Add_Click({
    $txtName.Text = ""
    $txtAge.Text = ""
    $txtPosition.Text = ""
    $cmbDept.SelectedIndex = 0
    $txtName.Focus()
})

# 搜索
$btnSearch.Add_Click({
    $keyword = $txtSearch.Text
    if ([string]::IsNullOrWhiteSpace($keyword)) {
        $dgEmployees.ItemsSource = $null
        $dgEmployees.ItemsSource = $script:employees
    } else {
        $filtered = $script:employees | Where-Object {
            $_.Name -like "*$keyword*" -or $_.Dept -like "*$keyword*" -or $_.Position -like "*$keyword*"
        }
        $dgEmployees.ItemsSource = @($filtered)
    }
})

# 导出 CSV
$btnExport.Add_Click({
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Filter = "CSV文件|*.csv"
    $dialog.DefaultExt = ".csv"
    if ($dialog.ShowDialog()) {
        $script:employees | Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.MessageBox]::Show("导出成功!", "提示")
    }
})

# 显示窗口
Update-Status
$window.ShowDialog() | Out-Null